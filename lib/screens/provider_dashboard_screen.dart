import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'landing_screen.dart';

class ProviderDashboardScreen extends StatelessWidget {
  static const routeName = '/providerHome';
  const ProviderDashboardScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: const Color(0xFF0078D4),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context))],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.engineering, size: 40)),
            const SizedBox(height: 16),
            Text('Welcome, ${user?.username ?? ''}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Provider dashboard — coming soon'),
          ],
        ),
      ),
    );
  }
}
