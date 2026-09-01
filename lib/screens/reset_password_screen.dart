import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/message_dialog.dart';
import '../widgets/otp_input_field.dart';
import 'login_screen.dart';

class ResetPasswordArgs {
  final String mobileNo;
  const ResetPasswordArgs({required this.mobileNo});
}

class ResetPasswordScreen extends StatefulWidget {
  static const routeName = '/reset-password';
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ResetPasswordArgs? _args;
  String _otp = '';
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _resetting = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null) {
      _args = ModalRoute.of(context)!.settings.arguments as ResetPasswordArgs;
      _startCooldown();
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resendOtp() async {
    final args = _args!;
    final authProvider = context.read<AuthProvider>();
    setState(() => _resending = true);

    final success = await authProvider.resendOtp(args.mobileNo, otpType: 'PasswordReset');
    if (!mounted) return;
    setState(() => _resending = false);

    if (success) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP resent to ${args.mobileNo}')));
    } else {
      await showMessageDialog(
        context,
        title: 'Request Failed',
        message: authProvider.error ?? 'Failed to resend OTP',
        type: MessageDialogType.error,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the complete 6-digit code')));
      return;
    }

    final args = _args!;
    final authProvider = context.read<AuthProvider>();
    setState(() => _resetting = true);

    final success = await authProvider.resetPassword(
      args.mobileNo,
      _otp,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _resetting = false);

    if (success) {
      await showMessageDialog(
        context,
        title: 'Password Reset',
        message: 'Password reset successfully. Please log in.',
        type: MessageDialogType.success,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
    } else {
      await showMessageDialog(
        context,
        title: 'Reset Failed',
        message: authProvider.error ?? 'Failed to reset password',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args!;
    final authProvider = context.watch<AuthProvider>();
    final devOtp = authProvider.otpData?.otp;

    return AuthCardScaffold(
      title: 'Reset Password',
      subtitle: 'Enter the code sent to ${args.mobileNo} and choose a new password',
      avatarIcon: Icons.lock_reset,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (devOtp != null && devOtp.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kAccentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kAccentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: kAccentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          children: [
                            const TextSpan(text: 'Development mode — OTP: '),
                            TextSpan(text: devOtp, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            OtpInputField(onChanged: (value) => _otp = value, prefillCode: devOtp),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code? ", style: TextStyle(color: Colors.black54)),
                _resending
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : GestureDetector(
                        onTap: _resendCooldown > 0 ? null : _resendOtp,
                        child: Text(
                          _resendCooldown > 0 ? 'Resend in ${_resendCooldown}s' : 'Resend',
                          style: TextStyle(
                            color: _resendCooldown > 0 ? Colors.black38 : kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 28),
            authFieldLabel('New Password'),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: authFieldDecoration(
                hint: 'Enter your new password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Confirm New Password'),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: authFieldDecoration(
                hint: 'Re-enter your new password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) => (v != _newPasswordController.text) ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Reset Password', isLoading: _resetting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
