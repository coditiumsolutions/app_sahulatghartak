import 'package:flutter/material.dart';

import 'customer_registration_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  static const routeName = '/landing';
  const LandingScreen({super.key});

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);
  static const _brandAccent = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brandDark, _brandBlue],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _brandAccent.withValues(alpha: 0.12)),
              ),
            ),
            Positioned(
              top: -30,
              right: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _brandAccent.withValues(alpha: 0.08)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.asset('assets/icon/app_icon.png', width: 168, height: 168),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Sahulat Ghar Tak', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Quality Services Delivered to Your Doorstep',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandAccent,
                              foregroundColor: _brandDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(context).pushNamed(CustomerRegistrationScreen.routeName),
                            child: const Text('Register', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(context).pushNamed(LoginScreen.routeName),
                            child: const Text('Login', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(HomeScreen.routeName),
                    style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.85)),
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
