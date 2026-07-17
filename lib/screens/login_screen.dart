import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import 'customer_registration_screen.dart';
import 'home_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mobileNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(_mobileNoController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (success) {
      final role = authProvider.role;
      if (role == 'Provider') {
        Navigator.of(context).pushReplacementNamed(ProviderDashboardScreen.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Login failed')));
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  Widget _socialButton({required IconData icon, required Color color, required String label}) {
    return InkWell(
      onTap: () => _showComingSoon(label),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expectedRole = ModalRoute.of(context)?.settings.arguments as String?;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthCardScaffold(
      title: expectedRole == 'Provider' ? 'Provider Login' : 'Login Account',
      subtitle: 'Welcome back to app',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel('Mobile Number'),
            TextFormField(
              controller: _mobileNoController,
              keyboardType: TextInputType.phone,
              decoration: authFieldDecoration(hint: 'Enter your mobile number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: authFieldDecoration(
                hint: 'Enter your password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showComingSoon('Password reset'),
                child: const Text('Forgot password?', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            AuthPrimaryButton(label: 'Login', isLoading: isLoading, onPressed: _submit),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE5E5EA))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Or sign up with', style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13)),
                ),
                const Expanded(child: Divider(color: Color(0xFFE5E5EA))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialButton(icon: Icons.g_mobiledata, color: const Color(0xFFDB4437), label: 'Google sign-in'),
                const SizedBox(width: 20),
                _socialButton(icon: Icons.facebook, color: const Color(0xFF1877F2), label: 'Facebook sign-in'),
                const SizedBox(width: 20),
                _socialButton(icon: Icons.apple, color: Colors.black, label: 'Apple sign-in'),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Not register yet? ", style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacementNamed(
                    expectedRole == 'Provider' ? ProviderRegistrationScreen.routeName : CustomerRegistrationScreen.routeName,
                  ),
                  child: const Text('Create account', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
