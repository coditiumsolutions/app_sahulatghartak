import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/client_address.dart';
import '../providers/auth_provider.dart';
import '../providers/client_address_provider.dart';
import '../providers/customer_service_request_provider.dart';
import '../utils/constants.dart';
import '../utils/service_title_suggestions.dart';
import 'add_address_screen.dart';
import 'service_requests_screen.dart';

class ServiceRequestFormScreen extends StatefulWidget {
  static const routeName = '/service-request/new';
  const ServiceRequestFormScreen({Key? key}) : super(key: key);

  @override
  State<ServiceRequestFormScreen> createState() => _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _budgetController = TextEditingController();
  final _remarksController = TextEditingController();

  Category? _category;
  String? _selectedServiceTitle;
  ClientAddress? _selectedAddress;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isUrgent = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _category = ModalRoute.of(context)!.settings.arguments as Category;

    final user = context.read<AuthProvider>().currentUser;
    _contactPersonController.text = user?.username ?? '';
    _contactNoController.text = user?.mobileNo ?? '';

    final clientUid = user?.providerUid;
    if (clientUid != null) {
      context.read<ClientAddressProvider>().loadAddresses(clientUid).then((_) {
        if (!mounted) return;
        final addresses = context.read<ClientAddressProvider>().addresses;
        if (addresses.isNotEmpty) {
          setState(() => _selectedAddress = addresses.first);
        }
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactPersonController.dispose();
    _contactNoController.dispose();
    _budgetController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _selectedTime = t);
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an address')));
      return;
    }
    final clientUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (clientUid == null) return;

    final requestProvider = context.read<CustomerServiceRequestProvider>();
    final success = await requestProvider.createRequest(
      clientUid: clientUid,
      categoryUid: _category!.id,
      clientAddressUid: _selectedAddress!.uid,
      serviceTitle: _selectedServiceTitle!,
      serviceDescription: _descriptionController.text.trim(),
      preferredServiceDate: _selectedDate == null ? '' : DateFormat('yyyy-MM-dd').format(_selectedDate!),
      preferredServiceTime: _selectedTime == null ? '' : _formatTime(_selectedTime!),
      isUrgent: _isUrgent,
      contactPerson: _contactPersonController.text.trim(),
      contactNo: _contactNoController.text.trim(),
      estimatedBudget: double.tryParse(_budgetController.text.trim()),
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service request submitted')));
      Navigator.of(context).pushReplacementNamed(ServiceRequestsScreen.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(requestProvider.error ?? 'Failed to submit request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = context.watch<ClientAddressProvider>();
    final saving = context.watch<CustomerServiceRequestProvider>().saving;

    return Scaffold(
      appBar: AppBar(title: Text(_category?.name ?? 'Service Request'), backgroundColor: kPrimaryColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Requesting: ${_category?.name ?? ''}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (addressState.loading)
                const Center(child: CircularProgressIndicator())
              else if (addressState.addresses.isEmpty)
                Card(
                  color: Colors.amber[50],
                  child: ListTile(
                    leading: const Icon(Icons.location_off, color: Colors.orange),
                    title: const Text('No saved addresses'),
                    subtitle: const Text('Add an address to continue'),
                    trailing: TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(AddAddressScreen.routeName),
                      child: const Text('Add'),
                    ),
                  ),
                )
              else
                DropdownButtonFormField<ClientAddress>(
                  value: _selectedAddress,
                  decoration: const InputDecoration(labelText: 'Service Address', border: OutlineInputBorder()),
                  items: addressState.addresses
                      .map((a) => DropdownMenuItem(value: a, child: Text('${a.addressTitle} - ${a.area}, ${a.city}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAddress = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedServiceTitle,
                decoration: const InputDecoration(labelText: 'Service Title', border: OutlineInputBorder()),
                items: getServiceTitleSuggestions(_category?.name ?? '')
                    .map((title) => DropdownMenuItem(value: title, child: Text(title, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedServiceTitle = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Service Description (optional)', border: OutlineInputBorder()),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as Urgent'),
                value: _isUrgent,
                onChanged: (v) => setState(() => _isUrgent = v),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(labelText: 'Contact Person', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactNoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Estimated Budget (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks (optional)', border: OutlineInputBorder()),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Text('Preferred Date & Time (optional)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today, size: 18), label: Text(_selectedDate == null ? 'Preferred Date' : DateFormat.yMMMd().format(_selectedDate!)))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.access_time, size: 18), label: Text(_selectedTime == null ? 'Preferred Time' : _selectedTime!.format(context)))),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saving ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
