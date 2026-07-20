import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/main_category.dart';

/// Square card used for the 3 top-level category groups on the home screen.
class MainCategoryCard extends StatelessWidget {
  final MainCategory category;
  final VoidCallback onTap;

  const MainCategoryCard({Key? key, required this.category, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Animate(
        effects: const [ScaleEffect(duration: Duration(milliseconds: 300)), FadeEffect()],
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: category.color.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, size: 42, color: category.color),
                const SizedBox(height: 8),
                Text(
                  category.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
