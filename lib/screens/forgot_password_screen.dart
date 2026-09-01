import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/message_dialog.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNoController = TextEditingController();

  @override
  void dispose() {
    _mobileNoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final mobileNo = _mobileNoController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(mobileNo, otpType: 'PasswordReset');

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamed(
        ResetPasswordScreen.routeName,
        arguments: ResetPasswordArgs(mobileNo: mobileNo),
      );
    } else {
      await showMessageDialog(
        context,
        title: 'Request Failed',
        message: authProvider.error ?? 'Failed to send reset code',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthCardScaffold(
      title: 'Forgot Password',
      subtitle: 'Enter your mobile number to receive a reset code',
      avatarIcon: Icons.lock_reset,
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
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Send Reset Code', isLoading: isLoading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
