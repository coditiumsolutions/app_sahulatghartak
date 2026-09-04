import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/customer_terms_and_conditions.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/message_dialog.dart';
import '../widgets/terms_and_conditions_section.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  static const routeName = '/register-customer';
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a gender')));
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms and Conditions')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final mobileNo = _phoneController.text.trim();
    final password = _passwordController.text;
    final success = await authProvider.registerCustomer(
      fullName: _fullNameController.text.trim(),
      mobileNo: mobileNo,
      password: password,
      confirmPassword: _confirmPasswordController.text,
      gender: _selectedGender!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(
        OtpVerificationScreen.routeName,
        arguments: OtpVerificationArgs(mobileNo: mobileNo, password: password, otpType: 'Registration'),
      );
    } else {
      await showMessageDialog(
        context,
        title: 'Registration Failed',
        message: authProvider.error ?? 'Registration failed',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AuthCardScaffold(
      title: 'Create Account',
      subtitle: 'Register as a customer',
      avatarIcon: Icons.person_add_alt_1,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel('Full Name'),
            TextFormField(
              controller: _fullNameController,
              decoration: authFieldDecoration(hint: 'Enter your full name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Mobile Number'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: authFieldDecoration(hint: 'Enter your mobile number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Gender'),
            GenderSelector(
              initialValue: _selectedGender,
              onChanged: (value) => setState(() => _selectedGender = value),
              validator: (v) => v == null ? 'Required' : null,
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
              validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Confirm Password'),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: authFieldDecoration(
                hint: 'Re-enter your password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) => (v != _passwordController.text) ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 20),
            TermsAndConditionsSection(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v),
              termsTitle: customerTermsAndConditionsTitle,
              termsBody: customerTermsAndConditionsBody,
              termsClosing: customerTermsAndConditionsClosing,
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Register', isLoading: isLoading, onPressed: _agreedToTerms ? _submit : null),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacementNamed(LoginScreen.routeName, arguments: 'Customer'),
                  child: const Text('Login', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
