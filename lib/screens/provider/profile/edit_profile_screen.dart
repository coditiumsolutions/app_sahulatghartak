import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/provider/profile/edit';
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cnicController;
  late TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProviderDashboardProvider>().providerDetail;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _cnicController = TextEditingController(text: profile?.cnic ?? '');
    _experienceController = TextEditingController(text: (profile?.experienceYears ?? 0).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final dashboard = context.read<ProviderDashboardProvider>();
    final profile = dashboard.providerDetail;
    if (profile == null) return;

    final updated = profile.copyWith(
      fullName: _nameController.text.trim(),
      cnic: _cnicController.text.trim(),
      experienceYears: int.tryParse(_experienceController.text.trim()) ?? profile.experienceYears,
    );
    dashboard.updateProviderDetail(updated);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: kPrimaryColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _cnicController, decoration: const InputDecoration(labelText: 'CNIC', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(controller: _experienceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Experience (years)', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Save Changes')),
            ],
          ),
        ),
      ),
    );
  }
}
