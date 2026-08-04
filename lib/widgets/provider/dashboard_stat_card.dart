import 'package:flutter/material.dart';

class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.07), Colors.white],
            ),
            boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: color, size: 19),
                    ),
                    const Spacer(),
                    if (tappable)
                      Icon(Icons.arrow_outward_rounded, size: 16, color: color.withValues(alpha: 0.55)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF12182B), letterSpacing: -0.3, height: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
