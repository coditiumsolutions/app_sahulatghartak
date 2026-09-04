import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Square card representing a subcategory within a main category group.
/// [available] reflects whether this subcategory matched a real backend
/// service category; unmatched ones render muted since no request can be
/// submitted for them yet.
class SubCategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool available;
  final VoidCallback onTap;
  final int index;

  const SubCategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.available,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = available ? color : Colors.grey;

    return Animate(
      delay: Duration(milliseconds: 60 * index),
      effects: const [ScaleEffect(duration: Duration(milliseconds: 300)), FadeEffect()],
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5EA)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 24, backgroundColor: effectiveColor.withValues(alpha: 0.15), child: Icon(icon, size: 24, color: effectiveColor)),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: available ? Colors.black87 : Colors.black45),
                  ),
                  if (!available) ...[
                    const SizedBox(height: 2),
                    const Text('Coming soon', style: TextStyle(fontSize: 10, color: Colors.black38)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
