import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  static const routeName = '/register-provider';
  const ProviderRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _cnicController = TextEditingController();
  final _experienceController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _serviceTypeController.dispose();
    _cnicController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerProvider(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      categoryId: _selectedCategoryId!,
      serviceType: _serviceTypeController.text.trim(),
      cnic: _cnicController.text.trim(),
      experienceYears: int.parse(_experienceController.text.trim()),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful. Please login.')));
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName, arguments: 'Provider');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Registration'), backgroundColor: const Color(0xFF0078D4)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                validator: (v) => (v != _passwordController.text) ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 16),
              if (categoryProvider.isLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceTypeController,
                decoration: const InputDecoration(labelText: 'Service Type', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cnicController,
                decoration: const InputDecoration(labelText: 'CNIC', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Experience (years)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: isLoading ? null : _submit,
                child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
