import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/service.dart';
import '../screens/service_detail_screen.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final Color? backgroundColor;
  const ServiceCard({Key? key, required this.service, this.backgroundColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(ServiceDetailScreen.routeName, arguments: service.id),
      child: Animate(
        effects: const [ScaleEffect(duration: Duration(milliseconds: 300)), FadeEffect()],
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 32, backgroundColor: (backgroundColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.2), child: Icon(service.iconData, size: 36, color: backgroundColor ?? Theme.of(context).primaryColor)),
              const SizedBox(height: 12),
              Text(service.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
