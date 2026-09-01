import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/provider_terms_and_conditions.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/message_dialog.dart';
import '../widgets/terms_and_conditions_section.dart';
import 'category_picker_screen.dart';
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
  Category? _selectedCategory;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

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

  Future<void> _pickCategory() async {
    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute(builder: (_) => CategoryPickerScreen(selectedCategoryId: _selectedCategory?.id)),
    );
    if (result != null) setState(() => _selectedCategory = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a gender')));
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms and Conditions')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerProvider(
      fullName: _fullNameController.text.trim(),
      mobileNo: _phoneController.text.trim(),
      password: _passwordController.text,
      cnic: _cnicController.text.trim(),
      gender: _selectedGender!,
      experienceYears: int.parse(_experienceController.text.trim()),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
    );

    if (!mounted) return;

    if (success) {
      await showMessageDialog(
        context,
        title: 'Registration Successful',
        message: 'Registration successful.',
        type: MessageDialogType.success,
      );
      if (!mounted) return;
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
            FormField<Category>(
              initialValue: _selectedCategory,
              validator: (v) => v == null ? 'Required' : null,
              builder: (state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () async {
                        await _pickCategory();
                        state.didChange(_selectedCategory);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: authFieldDecoration(hint: 'Select your category').copyWith(
                          errorText: state.errorText,
                          suffixIcon: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
                        ),
                        child: Text(
                          _selectedCategory?.name ?? 'Select your category',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedCategory == null ? Colors.grey.shade600 : Colors.black87,
                            fontWeight: _selectedCategory == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
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
            const SizedBox(height: 20),
            TermsAndConditionsSection(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v),
              termsTitle: providerTermsAndConditionsTitle,
              termsBody: providerTermsAndConditionsBody,
              termsClosing: providerTermsAndConditionsClosing,
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Register', isLoading: isLoading, onPressed: _agreedToTerms ? _submit : null),
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
