import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
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
  final _cnicController = TextEditingController();
  String? _selectedGender;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a gender')));
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
      cnic: _cnicController.text.trim(),
      gender: _selectedGender!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed(
        OtpVerificationScreen.routeName,
        arguments: OtpVerificationArgs(mobileNo: mobileNo, password: password, otpType: 'Registration'),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Registration failed')));
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
            authFieldLabel('CNIC'),
            TextFormField(
              controller: _cnicController,
              decoration: authFieldDecoration(hint: 'Enter your CNIC'),
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
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Register', isLoading: isLoading, onPressed: _submit),
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
