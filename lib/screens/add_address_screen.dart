import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_address.dart';
import '../providers/auth_provider.dart';
import '../providers/client_address_provider.dart';
import '../widgets/auth_card_scaffold.dart';

class AddAddressScreen extends StatefulWidget {
  static const routeName = '/add-address';
  final ClientAddress? existing;
  const AddAddressScreen({super.key, this.existing});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _fullAddressController;
  late final TextEditingController _areaController;
  late final TextEditingController _cityController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.addressTitle ?? '');
    _fullAddressController = TextEditingController(text: existing?.fullAddress ?? '');
    _areaController = TextEditingController(text: existing?.area ?? '');
    _cityController = TextEditingController(text: existing?.city ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullAddressController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final clientUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (clientUid == null) return;

    final addressProvider = context.read<ClientAddressProvider>();
    final existing = widget.existing;

    final success = existing == null
        ? await addressProvider.addAddress(
            clientUid: clientUid,
            addressTitle: _titleController.text.trim(),
            fullAddress: _fullAddressController.text.trim(),
            area: _areaController.text.trim(),
            city: _cityController.text.trim(),
          )
        : await addressProvider.updateAddress(
            addressUid: existing.uid,
            clientUid: clientUid,
            addressTitle: _titleController.text.trim(),
            fullAddress: _fullAddressController.text.trim(),
            area: _areaController.text.trim(),
            city: _cityController.text.trim(),
            latitude: existing.latitude,
            longitude: existing.longitude,
          );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Address updated' : 'Address added')));
    } else {
      final error = addressProvider.error ?? 'Failed to save address';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ClientAddressProvider>().saving;

    return AuthCardScaffold(
      title: _isEditing ? 'Edit Address' : 'Add Address',
      subtitle: _isEditing ? 'Update your saved address details' : 'Save an address for faster bookings',
      avatarIcon: Icons.location_on_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authFieldLabel('Address Title'),
            TextFormField(
              controller: _titleController,
              decoration: authFieldDecoration(hint: 'e.g. Home, Office'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Full Address'),
            TextFormField(
              controller: _fullAddressController,
              decoration: authFieldDecoration(hint: 'House no, street, landmark'),
              minLines: 2,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Area'),
            TextFormField(
              controller: _areaController,
              decoration: authFieldDecoration(hint: 'Enter area'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('City'),
            TextFormField(
              controller: _cityController,
              decoration: authFieldDecoration(hint: 'Enter city'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: _isEditing ? 'Save Changes' : 'Save Address', isLoading: saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
