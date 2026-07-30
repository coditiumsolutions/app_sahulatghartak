import 'package:flutter/material.dart';

/// Curved, colour-blocked header used across profile-style screens
/// (matches the "Home Maintenance" subcategory screen: a solid colour
/// band with soft decorative circles, a rounded white sheet below it,
/// and a circular avatar overlapping the seam).
class CurvedProfileHeader extends StatelessWidget {
  final Widget avatar;
  final Widget child;
  final Color color;
  final List<Color>? headerColors;
  final double headerHeight;
  final double avatarRadius;
  final Future<void> Function()? onRefresh;

  const CurvedProfileHeader({
    Key? key,
    required this.avatar,
    required this.child,
    required this.color,
    this.headerColors,
    this.headerHeight = 150,
    this.avatarRadius = 48,
    this.onRefresh,
  }) : super(key: key);

  Widget _blob(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
      );

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: BoxDecoration(
        color: headerColors == null ? color : null,
        gradient: headerColors == null
            ? null
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: headerColors!),
      ),
      child: Stack(
        children: [
          Positioned(top: -70, left: -50, child: _blob(180)),
          Positioned(top: -30, right: -60, child: _blob(160)),
          Positioned(bottom: headerHeight * 0.15, right: -40, child: _blob(120)),
          Column(
            children: [
              SizedBox(height: headerHeight),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  child: Container(color: Colors.white, child: child),
                ),
              ),
            ],
          ),
          Positioned(
            top: headerHeight - avatarRadius,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(6),
                child: avatar,
              ),
            ),
          ),
        ],
      ),
    );

    if (onRefresh == null) return body;
    return RefreshIndicator(onRefresh: onRefresh!, child: body);
  }
}

/// Prominent stat-style badge for highlighting a key profile fact
/// (e.g. Account Type, User ID) at the top of a profile screen.
class ProfileStatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const ProfileStatBadge({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
