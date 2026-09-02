import 'package:flutter/material.dart';

/// A horizontal, labelled step indicator visualizing a request/booking's
/// progress across a fixed sequence of statuses (e.g. Requested -> Assigned
/// -> In Progress -> Completed).
///
/// Terminal negative states (Cancelled/Rejected) don't fit the forward
/// progression, so pass [terminalLabel] to render a flat banner instead of a
/// partially-filled stepper.
class StatusProgressBar extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final Color activeColor;
  final String? terminalLabel;
  final Color? terminalColor;
  final bool compact;

  const StatusProgressBar({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.activeColor,
    this.terminalLabel,
    this.terminalColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (terminalLabel != null) {
      final color = terminalColor ?? Colors.red;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 9, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_rounded, size: compact ? 13 : 15, color: color),
            const SizedBox(width: 6),
            Text(terminalLabel!,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: compact ? 11 : 12.5)),
          ],
        ),
      );
    }

    final clampedStep = currentStep.clamp(0, steps.length - 1);
    final circleSize = compact ? 16.0 : 26.0;
    final lineHeight = compact ? 2.0 : 3.0;
    final labelSize = compact ? 8.5 : 11.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final segmentIndex = i ~/ 2;
          final filled = segmentIndex < clampedStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: circleSize / 2 - lineHeight / 2),
              child: Container(height: lineHeight, color: filled ? activeColor : Colors.grey.shade300),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final done = stepIndex < clampedStep;
        final active = stepIndex == clampedStep;
        final borderColor = done || active ? activeColor : Colors.grey.shade300;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? activeColor : Colors.white,
                border: Border.all(color: borderColor, width: compact ? 1.5 : 2),
              ),
              child: done
                  ? Icon(Icons.check, size: compact ? 10 : 15, color: Colors.white)
                  : active
                      ? Container(
                          width: compact ? 6 : 9,
                          height: compact ? 6 : 9,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
                        )
                      : null,
            ),
            SizedBox(height: compact ? 3 : 5),
            SizedBox(
              width: circleSize + (compact ? 34 : 44),
              child: Text(
                steps[stepIndex],
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: done || active ? const Color(0xFF1A2233) : Colors.grey[400],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
