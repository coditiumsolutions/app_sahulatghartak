import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class OtpVerificationArgs {
  final String mobileNo;
  final String? password;
  final String otpType;

  const OtpVerificationArgs({
    required this.mobileNo,
    this.password,
    this.otpType = 'Registration',
  });
}

class OtpVerificationScreen extends StatefulWidget {
  static const routeName = '/verify-otp';
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _otpLength = 6;
  final List<TextEditingController> _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  OtpVerificationArgs? _args;
  bool _initialSendTriggered = false;
  bool _verifying = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)!.settings.arguments as OtpVerificationArgs;
    if (!_initialSendTriggered) {
      _initialSendTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp(initial: true));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  void _fillOtp(String otp) {
    for (var i = 0; i < _otpLength && i < otp.length; i++) {
      _controllers[i].text = otp[i];
    }
    setState(() {});
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

  Future<void> _sendOtp({bool initial = false}) async {
    final args = _args!;
    final authProvider = context.read<AuthProvider>();
    if (!initial) setState(() => _resending = true);

    final success = initial
        ? await authProvider.sendOtp(args.mobileNo, otpType: args.otpType)
        : await authProvider.resendOtp(args.mobileNo, otpType: args.otpType);

    if (!mounted) return;
    if (!initial) setState(() => _resending = false);

    if (success) {
      _startCooldown();
      final devOtp = authProvider.otpData?.otp;
      if (devOtp != null && devOtp.isNotEmpty) {
        _fillOtp(devOtp);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(initial ? 'OTP sent to ${args.mobileNo}' : 'OTP resent to ${args.mobileNo}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Failed to send OTP')));
    }
  }

  Future<void> _verify() async {
    final otp = _enteredOtp;
    if (otp.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the complete 6-digit code')));
      return;
    }

    final args = _args!;
    final authProvider = context.read<AuthProvider>();
    setState(() => _verifying = true);

    final verified = await authProvider.verifyOtp(args.mobileNo, otp);
    if (!mounted) return;

    if (!verified) {
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Verification failed')));
      return;
    }

    if (args.password != null) {
      final loggedIn = await authProvider.login(args.mobileNo, args.password!);
      if (!mounted) return;
      setState(() => _verifying = false);

      if (loggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account verified successfully.')));
        Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Login failed')));
        Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
      }
    } else {
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number verified successfully.')));
      Navigator.of(context).pop(true);
    }
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF5F5F7),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < _otpLength - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args!;
    final authProvider = context.watch<AuthProvider>();
    final devOtp = authProvider.otpData?.otp;

    return AuthCardScaffold(
      title: 'Verify OTP',
      subtitle: 'Enter the 6-digit code sent to ${args.mobileNo}',
      avatarIcon: Icons.sms_outlined,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, _otpBox),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(label: 'Verify', isLoading: _verifying, onPressed: _verify),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Didn't receive the code? ", style: TextStyle(color: Colors.black54)),
              _resending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onTap: _resendCooldown > 0 ? null : () => _sendOtp(),
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
        ],
      ),
    );
  }
}
