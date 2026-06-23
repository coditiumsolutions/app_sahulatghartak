import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

class LandingScreen extends StatelessWidget {
  static const routeName = '/landing';
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 16),
            Text('Sahulat Ghar Tak', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Quality Services Delivered to Your Doorstep', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.of(context).pushNamed(RoleSelectionScreen.routeName),
              child: const SizedBox(width: double.infinity, child: Text('Register', textAlign: TextAlign.center)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.of(context).pushNamed(LoginScreen.routeName, arguments: 'Customer'),
              child: const SizedBox(width: double.infinity, child: Text('Customer Login', textAlign: TextAlign.center)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.of(context).pushNamed(LoginScreen.routeName, arguments: 'Provider'),
              child: const SizedBox(width: double.infinity, child: Text('Provider Login', textAlign: TextAlign.center)),
            ),
          ],
        ),
      ),
    );
  }
}
