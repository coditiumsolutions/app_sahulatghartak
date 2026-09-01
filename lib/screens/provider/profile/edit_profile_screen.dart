import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../widgets/auth_card_scaffold.dart';
import '../../../widgets/provider/provider_tab_header.dart';

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
  bool _saving = false;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dashboard = context.read<ProviderDashboardProvider>();
    final profile = dashboard.providerDetail;
    if (profile == null) return;

    final updated = profile.copyWith(
      fullName: _nameController.text.trim(),
      cnic: _cnicController.text.trim(),
      experienceYears: int.tryParse(_experienceController.text.trim()) ?? profile.experienceYears,
    );

    setState(() => _saving = true);
    final success = await dashboard.updateProviderDetail(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dashboard.profileError ?? 'Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Edit Profile',
        subtitle: 'Update your personal details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              authFieldLabel('Full Name'),
              TextFormField(
                controller: _nameController,
                decoration: authFieldDecoration(hint: 'Enter your full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              authFieldLabel('CNIC'),
              TextFormField(controller: _cnicController, decoration: authFieldDecoration(hint: 'Enter your CNIC')),
              const SizedBox(height: 20),
              authFieldLabel('Experience (years)'),
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: authFieldDecoration(hint: 'Enter years of experience'),
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(label: 'Save Changes', isLoading: _saving, onPressed: _save, color: providerBrandBlue),
            ],
          ),
        ),
      ),
    );
  }
}
