import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'customer_registration_screen.dart';
import 'provider_registration_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  static const routeName = '/register';
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as'), backgroundColor: const Color(0xFF0078D4)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('How would you like to join?', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.of(context).pushNamed(CustomerRegistrationScreen.routeName),
              label: const SizedBox(width: double.infinity, child: Text('Customer', textAlign: TextAlign.center)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kSecondaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.engineering),
              onPressed: () => Navigator.of(context).pushNamed(ProviderRegistrationScreen.routeName),
              label: const SizedBox(width: double.infinity, child: Text('Service Provider', textAlign: TextAlign.center)),
            ),
          ],
        ),
      ),
    );
  }
}
