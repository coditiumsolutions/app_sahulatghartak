import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// A 3-way segmented pill selector ("Active" / "Completed" / "Cancelled")
/// used to split the customer requests and provider bookings lists instead
/// of showing every status in one long scroll. Purely a client-side filter
/// over the already-loaded list — no extra API calls.
///
/// The selected pill is a single sliding indicator (not a per-item color
/// fade) — it animates its position across the track on tab change, with
/// label color/weight cross-fading in step, for a tactile segmented-control
/// feel instead of a flat swap.
class StatusFilterTabs extends StatelessWidget {
  final List<String> labels;
  final List<int> counts;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color activeColor;

  const StatusFilterTabs({
    super.key,
    required this.labels,
    required this.counts,
    required this.selectedIndex,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFEAEFF6),
          borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / labels.length;
          final reduceMotion = prefersReducedMotion(context);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: reduceMotion ? Duration.zero : kMediumAnimDuration,
                curve: kEmphasizedCurve,
                top: 0,
                bottom: 0,
                left: segmentWidth * selectedIndex,
                width: segmentWidth,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final selected = i == selectedIndex;
                  return SizedBox(
                    width: segmentWidth,
                    height: double.infinity,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: reduceMotion
                                ? Duration.zero
                                : kMediumAnimDuration,
                            curve: kStandardCurve,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12.5,
                              color: selected ? activeColor : Colors.grey[600],
                            ),
                            child: Text(
                              '${labels[i]} (${counts[i]})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
