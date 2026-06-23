import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'landing_screen.dart';
import 'provider_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final authProvider = context.read<AuthProvider>();
    await Future.wait([
      authProvider.tryAutoLogin(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    if (!authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(LandingScreen.routeName);
    } else if (authProvider.role == 'Provider') {
      Navigator.of(context).pushReplacementNamed(ProviderDashboardScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 16),
            Text('Sahulat Ghar Tak', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Quality Services Delivered to Your Doorstep', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          ],
        ).animate().fade().scale(),
      ),
    );
  }
}
