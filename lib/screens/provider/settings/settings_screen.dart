import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../screens/landing_screen.dart';
import '../../../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/provider/settings';
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
  }

  void _changePassword(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _selectLanguage(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('English')),
          SimpleDialogOption(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('اردو (Urdu)')),
        ],
      ),
    );
  }

  void _showStaticPage(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: kPrimaryColor),
      body: ListView(
        children: [
          ListTile(leading: const Icon(Icons.lock, color: kPrimaryColor), title: const Text('Change Password'), onTap: () => _changePassword(context)),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.language, color: kPrimaryColor), title: const Text('Language'), onTap: () => _selectLanguage(context)),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: kPrimaryColor),
            title: const Text('Notifications'),
            value: true,
            activeThumbColor: kPrimaryColor,
            onChanged: (_) {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: kPrimaryColor),
            title: const Text('Privacy Policy'),
            onTap: () => _showStaticPage(context, 'Privacy Policy', 'Your data is kept secure and is only used to improve your service experience on Sahulat Ghar Tak.'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: kPrimaryColor),
            title: const Text('Terms & Conditions'),
            onTap: () => _showStaticPage(context, 'Terms & Conditions', 'By using Sahulat Ghar Tak as a service provider, you agree to deliver services professionally and abide by platform policies.'),
          ),
          const Divider(height: 1),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red)), onTap: () => _logout(context)),
        ],
      ),
    );
  }
}
