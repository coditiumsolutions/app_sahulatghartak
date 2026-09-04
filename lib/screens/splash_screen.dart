import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/breakpoints.dart';
import '../utils/motion.dart';
import 'home_screen.dart';
import 'landing_screen.dart';
import 'provider_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

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

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);

  @override
  Widget build(BuildContext context) {
    final logoSize = appLogoSize(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Image.asset('assets/icon/app_icon.png', width: logoSize, height: logoSize),
          ),
        ),
        const SizedBox(height: 24),
        Text('Sahulat Ghar Tak', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Quality Services Delivered to Your Doorstep', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brandDark, _brandBlue],
          ),
        ),
        child: Center(
          child: prefersReducedMotion(context)
              ? content
              : content.animate().fade(duration: kSlowAnimDuration, curve: kStandardCurve).scale(duration: kSlowAnimDuration, curve: kStandardCurve),
        ),
      ),
    );
  }
}
