import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/message_dialog.dart';
import 'customer_registration_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'otp_verification_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

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
      // Clear the whole stack (Landing + Login) instead of just replacing
      // Login — otherwise LandingScreen remains underneath and a back-press
      // from the dashboard drops the user onto what looks like a logged-out
      // screen, even though the session is still active.
      final target = role == 'Provider' ? ProviderDashboardScreen.routeName : HomeScreen.routeName;
      Navigator.of(context).pushNamedAndRemoveUntil(target, (route) => false);
    } else if (authProvider.isUnverified) {
      Navigator.of(context).pushNamed(
        OtpVerificationScreen.routeName,
        arguments: OtpVerificationArgs(
          mobileNo: _mobileNoController.text.trim(),
          password: _passwordController.text,
          otpType: 'Registration',
        ),
      );
    } else {
      await showMessageDialog(
        context,
        title: 'Login Failed',
        message: authProvider.error ?? 'Login failed',
        type: MessageDialogType.error,
      );
    }
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
                onPressed: () => Navigator.of(context).pushNamed(ForgotPasswordScreen.routeName),
                child: const Text('Forgot password?', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            AuthPrimaryButton(label: 'Login', isLoading: isLoading, onPressed: _submit),
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
