import 'package:flutter/material.dart';

import '../../utils/motion.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final duration = prefersReducedMotion(context) ? Duration.zero : kQuickAnimDuration;
    return AnimatedSize(
      duration: duration,
      curve: kStandardCurve,
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: kStandardCurve,
        switchOutCurve: kStandardCurve,
        child: Container(
          key: ValueKey<String>(label),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }
}
