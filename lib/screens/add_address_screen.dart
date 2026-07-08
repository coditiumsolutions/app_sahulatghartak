import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_address.dart';
import '../providers/auth_provider.dart';
import '../providers/client_address_provider.dart';
import '../utils/constants.dart';

class AddAddressScreen extends StatefulWidget {
  static const routeName = '/add-address';
  final ClientAddress? existing;
  const AddAddressScreen({Key? key, this.existing}) : super(key: key);

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

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Address' : 'Add Address'), backgroundColor: kPrimaryColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Address Title (e.g. Home, Office)', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullAddressController,
                decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saving ? null : _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Save Changes' : 'Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
