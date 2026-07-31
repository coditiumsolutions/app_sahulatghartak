import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/service.dart';
import '../screens/service_detail_screen.dart';
import '../utils/service_colors.dart';

/// Tapping it grows this card into [ServiceDetailScreen] via a Material
/// container-transform, so the destination visually emerges from the
/// tapped card instead of sliding in as a separate page.
class ServiceCard extends StatelessWidget {
  final Service service;
  final Color? backgroundColor;
  const ServiceCard({super.key, required this.service, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? colorForServiceId(service.id);
    return Animate(
      effects: const [ScaleEffect(duration: Duration(milliseconds: 300)), FadeEffect()],
      child: OpenContainer(
        closedElevation: 0,
        openElevation: 0,
        closedColor: Colors.transparent,
        openColor: color,
        closedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        transitionDuration: const Duration(milliseconds: 420),
        closedBuilder: (context, openContainer) {
          return GestureDetector(
            onTap: openContainer,
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 32, backgroundColor: color.withValues(alpha: 0.2), child: Icon(service.iconData, size: 36, color: color)),
                  const SizedBox(height: 12),
                  Text(service.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
        openBuilder: (context, closeContainer) {
          return ServiceDetailScreen(serviceId: service.id, onClose: closeContainer);
        },
      ),
    );
  }
}
