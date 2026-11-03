import 'package:flutter/material.dart';
import '../../../widgets/frosted_icon_button.dart';
import 'package:provider/provider.dart';

import '../../../providers/city_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/input_formatters.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/auth_card_scaffold.dart';
import '../../../widgets/inline_field_error.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/themed_dropdown.dart';

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
  late TextEditingController _descriptionController;
  int _experienceYears = 0;
  String? _selectedCity;
  String? _selectedGender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProviderDashboardProvider>().providerDetail;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _cnicController =
        TextEditingController(text: formatCnicForDisplay(profile?.cnic ?? ''));
    _descriptionController =
        TextEditingController(text: profile?.description ?? '');
    _experienceYears = profile?.experienceYears ?? 0;
    _selectedCity = profile?.city;
    _selectedGender =
        profile?.gender.isNotEmpty == true ? profile?.gender : null;
    context.read<CityProvider>().loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _descriptionController.dispose();
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
      experienceYears: _experienceYears,
      description: _descriptionController.text.trim(),
      city: _selectedCity,
      gender: _selectedGender,
    );

    setState(() => _saving = true);
    final success = await dashboard.updateProviderDetail(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      showAppToast(context, 'Profile updated', type: AppToastType.success);
      Navigator.of(context).pop();
    } else {
      showAppToast(
          context, dashboard.profileError ?? 'Failed to update profile',
          type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Edit Profile',
        subtitle: 'Update your personal details',
        leading: FrostedBackButton(onPressed: () => Navigator.of(context).maybePop(),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              GenderSelector(
                initialValue: _selectedGender,
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (v) => v == null ? 'Please select a gender' : null,
              ),
              const SizedBox(height: 20),
              authFieldLabel('CNIC'),
              TextFormField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                inputFormatters: [CnicInputFormatter()],
                decoration: authFieldDecoration(hint: '12345-1234567-1'),
                validator: cnicValidator,
              ),
              const SizedBox(height: 20),
              authFieldLabel('Experience (years)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E5)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: providerBrandBlue,
                      onPressed: _experienceYears > 0
                          ? () => setState(() => _experienceYears--)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        '$_experienceYears ${_experienceYears == 1 ? 'year' : 'years'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: providerBrandBlue,
                      onPressed: _experienceYears < 50
                          ? () => setState(() => _experienceYears++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              authFieldLabel('City'),
              Consumer<CityProvider>(
                builder: (context, cityProvider, _) {
                  if (cityProvider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (cityProvider.error != null &&
                      cityProvider.cities.isEmpty) {
                    return InlineFieldError(
                        message: cityProvider.error!,
                        onRetry: cityProvider.loadCities);
                  }
                  return ThemedDropdownField<String>(
                    value: _selectedCity,
                    hint: 'Select your city',
                    items: cityProvider.cities
                        .map((c) => ThemedDropdownItem(value: c, label: c))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCity = v),
                  );
                },
              ),
              const SizedBox(height: 20),
              authFieldLabel('About you'),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: authFieldDecoration(
                    hint: 'Briefly describe your services and experience'),
              ),
              const SizedBox(height: 28),
              AuthPrimaryButton(
                  label: 'Save Changes',
                  isLoading: _saving,
                  onPressed: _save,
                  color: providerBrandBlue),
            ],
          ),
        ),
      ),
    );
  }
}
