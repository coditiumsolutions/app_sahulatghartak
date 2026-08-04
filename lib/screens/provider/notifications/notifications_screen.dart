import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/provider_routes.dart';
import '../../../widgets/provider/provider_tab_header.dart';

/// Placeholder for the provider notifications feed. The backend endpoint for
/// this doesn't exist yet - this screen just reserves the entry point so the
/// Home page card has somewhere to go.
class NotificationsScreen extends StatelessWidget {
  static const routeName = ProviderRoutes.notifications;
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Notifications',
        subtitle: 'Stay up to date',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_active_outlined, size: 40, color: kPrimaryColor),
              ),
              const SizedBox(height: 20),
              const Text(
                'Notifications coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2233)),
              ),
              const SizedBox(height: 8),
              Text(
                "We're still building this page. Check back later for updates on your requests, bookings, and payments.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
