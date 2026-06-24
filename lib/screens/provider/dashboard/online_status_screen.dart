import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class OnlineStatusScreen extends StatelessWidget {
  static const routeName = '/provider/online-status';
  const OnlineStatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final isOnline = dashboard.isOnline;

    return Scaffold(
      appBar: AppBar(title: const Text('Online / Offline Status'), backgroundColor: kPrimaryColor),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(isOnline ? Icons.wifi_tethering : Icons.wifi_tethering_off, size: 64, color: isOnline ? Colors.green : Colors.grey),
                    const SizedBox(height: 16),
                    Text(isOnline ? "You're Online" : "You're Offline", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      isOnline ? 'You are receiving new service requests and sharing your current location.' : 'You will not receive new service requests while offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    Switch(value: isOnline, activeColor: Colors.green, onChanged: (v) => dashboard.setOnline(v)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(leading: const Icon(Icons.notifications_active, color: kPrimaryColor), title: const Text('Receive new service requests'), trailing: Icon(isOnline ? Icons.check_circle : Icons.cancel, color: isOnline ? Colors.green : Colors.grey)),
            ListTile(leading: const Icon(Icons.my_location, color: kPrimaryColor), title: const Text('Share current location'), trailing: Icon(isOnline ? Icons.check_circle : Icons.cancel, color: isOnline ? Colors.green : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
