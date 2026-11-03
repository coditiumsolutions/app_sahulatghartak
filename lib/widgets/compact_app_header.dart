import 'package:flutter/material.dart';
import 'frosted_icon_button.dart';

const _brandDark = Color(0xFF0A4FA8);
const _brandBlue = Color(0xFF016EE3);

/// Compact branded top bar — same gradient/rounded-bottom-corner styling as
/// [ProviderTabHeader] and the customer Requests page's banner, just shorter
/// (no subtitle, no leading icon badge, no decorative glow circles) for
/// screens like full-screen pickers where maximizing content height matters
/// more than a tall header.
class CompactAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const CompactAppHeader({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
  });

  /// Height of the tappable bar itself, below the device's top safe-area
  /// inset (status bar / notch / Dynamic Island) — [preferredSize] adds that
  /// inset on top so devices with a tall inset (e.g. Dynamic Island, ~59) get
  /// a taller header rather than the back button/title being squeezed under
  /// [SafeArea] padding inside a fixed-height box.
  static const double height = 56;

  @override
  Size get preferredSize => Size.fromHeight(height + _topInset);

  // Scaffold reads `preferredSize` before the first build (to size the AppBar
  // slot) without a BuildContext, so the inset has to come from the platform
  // dispatcher's view directly rather than MediaQuery.
  static double get _topInset {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.padding.top / view.devicePixelRatio;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brandBlue],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
              color: Color(0x330A4FA8), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                FrostedBackButton(onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2),
                  ),
                ),
                if (actions != null) ...actions!,
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
