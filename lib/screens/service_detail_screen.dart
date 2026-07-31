import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/service_provider.dart';
import '../utils/service_colors.dart';
import '../widgets/bottom_nav.dart';
import 'booking_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  static const routeName = '/service-detail';

  /// Optional explicit service id, used when pushed directly (e.g. via
  /// [OpenContainer]). Falls back to the route arguments when navigated to
  /// via [Navigator.pushNamed].
  final int? serviceId;

  /// When set (i.e. hosted inside an [OpenContainer]), the back button calls
  /// this instead of [Navigator.maybePop] so the closing transform animation
  /// plays instead of a plain route pop.
  final VoidCallback? onClose;

  const ServiceDetailScreen({super.key, this.serviceId, this.onClose});

  static const double _avatarRadius = 46;
  static const double _headerHeight = 170;

  @override
  Widget build(BuildContext context) {
    final args = serviceId ?? ModalRoute.of(context)!.settings.arguments as int?;
    final service = context.read<ServiceProvider>().services.firstWhere((s) => s.id == args);
    final color = colorForServiceId(service.id);

    return PopScope(
      canPop: onClose == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onClose?.call();
      },
      child: Scaffold(
      backgroundColor: color,
      bottomNavigationBar: const AppBottomNavigation(currentIndex: -1),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Positioned(
            top: -30,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: _headerHeight),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -60,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, _avatarRadius + 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Text(service.description, style: TextStyle(color: Colors.black.withValues(alpha: 0.6), height: 1.4)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                'Starting Price: PKR ${service.startingPrice.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Benefits', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(height: 4),
                            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle, color: color), title: const Text('Experienced Professionals')),
                            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle, color: color), title: const Text('Quality Assured')),
                            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle, color: color), title: const Text('On-time Service')),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => Navigator.of(context).pushNamed(BookingScreen.routeName, arguments: service),
                                child: const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: _headerHeight - _avatarRadius,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: _avatarRadius * 2,
                height: _avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: color,
                  child: Icon(service.iconData, color: Colors.white, size: 42),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
