import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/service_catalog.dart';
import '../screens/subcategories_screen.dart';
import '../utils/service_catalog_style.dart';

/// Square card used for the top-level service groups on the home screen.
/// Tapping it grows the colored card into [SubCategoriesScreen] via a
/// Material container-transform, so the destination visually emerges from
/// the tapped card instead of sliding in as a separate page.
class MainCategoryCard extends StatelessWidget {
  final ServiceCatalog service;
  final int index;

  const MainCategoryCard({super.key, required this.service, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final style = styleForServiceName(service.name, index);

    return Animate(
      delay: Duration(milliseconds: 60 * index),
      effects: const [ScaleEffect(duration: Duration(milliseconds: 300)), FadeEffect()],
      child: AspectRatio(
        aspectRatio: 1,
        child: OpenContainer(
          closedElevation: 0,
          openElevation: 0,
          closedColor: const Color(0xFFF4F7FB),
          openColor: style.color,
          closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          transitionDuration: const Duration(milliseconds: 380),
          closedBuilder: (context, openContainer) {
            return GestureDetector(
              onTap: openContainer,
              child: Container(
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: style.color.withValues(alpha: 0.4)),
                  boxShadow: [BoxShadow(color: style.color.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(style.icon, size: 42, color: style.color),
                    const SizedBox(height: 8),
                    Text(
                      service.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
          openBuilder: (context, closeContainer) {
            return SubCategoriesScreen(service: service, onClose: closeContainer);
          },
        ),
      ),
    );
  }
}
