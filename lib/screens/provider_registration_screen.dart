import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import 'login_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_document_upload_screen.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  static const routeName = '/register-provider';
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cnicController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGender;
  int? _selectedCategoryId;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthProvider>().currentUser;
    _fullNameController.text = currentUser?.username ?? '';
    _phoneController.text = currentUser?.mobileNo ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cnicController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a gender')));
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();
    final selectedCategory = categoryProvider.categories.firstWhere((c) => c.id == _selectedCategoryId);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerProvider(
      fullName: _fullNameController.text.trim(),
      mobileNo: _phoneController.text.trim(),
      password: _passwordController.text,
      cnic: _cnicController.text.trim(),
      gender: _selectedGender!,
      experienceYears: int.parse(_experienceController.text.trim()),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategoryId!,
      categoryName: selectedCategory.name,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful.')));
      final providerUid = authProvider.currentUser?.providerUid;
      if (providerUid != null) {
        Navigator.of(context).pushReplacementNamed(
          ProviderDocumentUploadScreen.routeName,
          arguments: ProviderDocumentUploadArgs(providerUid: providerUid),
        );
      } else {
        // Fallback: providerUid should always be present after a successful registration,
        // but don't strand the user on this screen if it's ever missing.
        Navigator.of(context).pushReplacementNamed(ProviderDashboardScreen.routeName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return AuthCardScaffold(
      title: 'Create Account',
      subtitle: 'Register as a service provider',
      avatarIcon: Icons.engineering,
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
              readOnly: true,
              enabled: false,
              keyboardType: TextInputType.phone,
              decoration: authFieldDecoration(hint: 'Enter your mobile number').copyWith(
                suffixIcon: const Icon(Icons.lock_outline, color: Colors.black38, size: 18),
                fillColor: const Color(0xFFEDEDEF),
              ),
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
            authFieldLabel('Confirm Your Account Password'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: authFieldDecoration(
                hint: 'Enter your existing account password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black45),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Category'),
            if (categoryProvider.isLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator()))
            else
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: authFieldDecoration(hint: 'Select your category'),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (value) => setState(() => _selectedCategoryId = value),
                validator: (v) => v == null ? 'Required' : null,
              ),
            const SizedBox(height: 20),
            authFieldLabel('Experience (years)'),
            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration: authFieldDecoration(hint: 'Enter years of experience'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),
            authFieldLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: authFieldDecoration(hint: 'Briefly describe your services'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Register', isLoading: isLoading, onPressed: _submit),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacementNamed(LoginScreen.routeName, arguments: 'Provider'),
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
