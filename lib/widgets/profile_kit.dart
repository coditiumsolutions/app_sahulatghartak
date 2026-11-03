import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/motion.dart';
import 'app_toast.dart';
import 'frosted_icon_button.dart';

/// Shared building blocks for the customer and provider profile pages, so both
/// read the same way: a quick-facts strip, label-over-value detail rows, a row
/// of quick actions, and a collapsed "Account details" drawer that keeps
/// internal IDs out of sight until someone needs them (e.g. for support).

const _ink = Color(0xFF14213D);

/// Soft page tint so white cards read as raised surfaces.
const kProfileBody = Color(0xFFF1F5FB);

/// Supporting hues around the brand blue (60% blue / 30% neutrals / 10%
/// accents). Each one carries a meaning so colour helps scanning instead of
/// decorating: teal = contact & availability, violet = identity, amber =
/// work & ratings, coral = time/history. Kept mid-saturation so they sit
/// calmly next to #016EE3.
const kProfileTeal = Color(0xFF0E9F8E);
const kProfileViolet = Color(0xFF7C5CFC);
const kProfileAmber = Color(0xFFF59E0B);
const kProfileCoral = Color(0xFFF2685B);

/// One figure in a [ProfileStatStrip].
class ProfileStat {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  const ProfileStat(
      {required this.icon,
      required this.value,
      required this.label,
      this.color});
}

/// A single white card holding 2-3 headline figures separated by hairlines.
class ProfileStatStrip extends StatelessWidget {
  final List<ProfileStat> stats;
  final Color accent;
  const ProfileStatStrip(
      {super.key, required this.stats, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: _cardDecoration(accent),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                    width: 1, color: Colors.black.withValues(alpha: 0.08)),
              Expanded(child: _StatCell(stat: stats[i], accent: accent)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final ProfileStat stat;
  final Color accent;
  const _StatCell({required this.stat, required this.accent});

  @override
  Widget build(BuildContext context) {
    final color = stat.color ?? accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
          child: Icon(stat.icon, size: 19, color: color),
        ),
        const SizedBox(height: 8),
        Text(stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 2),
        Text(stat.label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.45))),
      ],
    );
  }
}

/// Section heading with an optional trailing widget (e.g. an "Add" button).
class ProfileSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const ProfileSectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.2)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// White rounded card that stacks [children] with hairline dividers.
class ProfileCard extends StatelessWidget {
  final List<Widget> children;
  final Color shadow;
  const ProfileCard(
      {super.key,
      required this.children,
      this.shadow = const Color(0xFF0A4FA8)});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
            height: 1,
            indent: 56,
            color: Colors.black.withValues(alpha: 0.06)));
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: _cardDecoration(shadow),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// Icon + small label above a readable value. Replaces the old ListTile rows.
class ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Widget? trailing;

  /// Tap action for the whole row (e.g. open an editor).
  final VoidCallback? onTap;

  /// Shows a copy icon and copies [value] to the clipboard on tap.
  final bool copyable;
  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
    this.onTap,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = onTap ??
        (copyable
            ? () {
                Clipboard.setData(ClipboardData(text: value));
                showAppToast(context, '$label copied');
              }
            : null);
    final Widget? end = trailing ??
        (copyable
            ? Icon(Icons.copy_rounded,
                size: 16, color: Colors.black.withValues(alpha: 0.3))
            : (onTap != null
                ? Icon(Icons.chevron_right_rounded,
                    color: Colors.black.withValues(alpha: 0.3))
                : null));
    return InkWell(
        onTap: action,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.45))),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                            height: 1.3)),
                  ],
                ),
              ),
              if (end != null) ...[const SizedBox(width: 8), end],
            ],
          ),
        ));
  }
}

/// Detail row for sensitive values (e.g. CNIC): shows [maskedValue] until the
/// eye icon is tapped, so the number isn't readable over someone's shoulder.
class ProfileSecretRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String maskedValue;
  final Color color;
  const ProfileSecretRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.maskedValue,
    required this.color,
  });

  @override
  State<ProfileSecretRow> createState() => _ProfileSecretRowState();
}

class _ProfileSecretRowState extends State<ProfileSecretRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return ProfileDetailRow(
      icon: widget.icon,
      label: widget.label,
      value: _revealed ? widget.value : widget.maskedValue,
      color: widget.color,
      onTap: () => setState(() => _revealed = !_revealed),
      trailing: Icon(
          _revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 20,
          color: Colors.black.withValues(alpha: 0.35)),
    );
  }
}

/// `42101-1234567-3` -> `42101-*******-3`. Anything that isn't a 13-digit CNIC
/// is returned untouched.
String maskCnic(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 13) return raw;
  return '${digits.substring(0, 5)}-*******-${digits.substring(12)}';
}

/// App-bar logout button on the shared frosted-glass circle.
class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ProfileLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FrostedIconButton(
      tooltip: 'Log out',
      margin: const EdgeInsets.only(right: 12),
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 21),
    );
  }
}

/// Fades and lifts each child in on first build, with a short stagger. Skipped
/// when the platform's reduce-motion setting is on.
List<Widget> staggerProfile(BuildContext context, List<Widget> children) {
  if (prefersReducedMotion(context)) return children;
  return [
    for (var i = 0; i < children.length; i++)
      children[i]
          .animate(delay: Duration(milliseconds: 45 * (i < 10 ? i : 10)))
          .fadeIn(duration: kSlowAnimDuration, curve: kStandardCurve)
          .slideY(
              begin: 0.05,
              end: 0,
              duration: kSlowAnimDuration,
              curve: kEmphasizedCurve),
  ];
}

/// Grey placeholder blocks shaped like the profile page, with a soft shimmer.
/// Shown while the profile loads so the layout doesn't jump when data lands.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  Widget _block(double height, {double? width, double radius = 18}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: const Color(0xFFE3E9F2),
            borderRadius: BorderRadius.circular(radius)),
      );

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _block(22, width: 170, radius: 8)),
        const SizedBox(height: 8),
        Center(child: _block(14, width: 110, radius: 7)),
        const SizedBox(height: 20),
        _block(96),
        const SizedBox(height: 22),
        _block(18, width: 100, radius: 7),
        const SizedBox(height: 10),
        _block(120),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _block(86)),
          const SizedBox(width: 10),
          Expanded(child: _block(86)),
          const SizedBox(width: 10),
          Expanded(child: _block(86)),
        ]),
        const SizedBox(height: 22),
        _block(18, width: 120, radius: 7),
        const SizedBox(height: 10),
        _block(200),
      ],
    );
    if (prefersReducedMotion(context)) return body;
    return body
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.7));
  }
}

/// Small tappable tile for a row of quick actions (Edit, Documents, ...).
class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsed-by-default drawer listing internal IDs. Tap a row to copy it.
class ProfileIdsDrawer extends StatelessWidget {
  final Map<String, String> entries;
  final Color color;
  const ProfileIdsDrawer(
      {super.key, required this.entries, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(color),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          leading: Icon(Icons.tag_rounded, color: color),
          iconColor: color,
          title: const Text('Account details',
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
          subtitle: Text('IDs for support requests',
              style: TextStyle(
                  fontSize: 12, color: Colors.black.withValues(alpha: 0.45))),
          children: [
            for (final e in entries.entries)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: e.value));
                  showAppToast(context, '${e.key} copied');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.key,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withValues(alpha: 0.55))),
                      ),
                      Flexible(
                        child: Text(e.value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _ink)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy_rounded,
                          size: 14, color: Colors.black.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(Color shadow) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
            color: shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6))
      ],
    );
