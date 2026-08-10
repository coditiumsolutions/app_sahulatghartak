import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/client_address.dart';
import '../providers/auth_provider.dart';
import '../providers/client_address_provider.dart';
import '../providers/customer_service_request_provider.dart';
import '../providers/service_title_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/themed_dropdown.dart';
import 'add_address_screen.dart';
import 'service_requests_screen.dart';

/// Route arguments for [ServiceRequestFormScreen]: the selected backend
/// [Category] plus the parent service's accent color, so the form's accent
/// matches where the user came from.
class ServiceRequestFormArgs {
  final Category category;
  final Color color;
  const ServiceRequestFormArgs({required this.category, required this.color});
}

class ServiceRequestFormScreen extends StatefulWidget {
  static const routeName = '/service-request/new';
  const ServiceRequestFormScreen({super.key});

  @override
  State<ServiceRequestFormScreen> createState() => _ServiceRequestFormScreenState();
}

/// Sentinel dropdown value for "my job isn't listed" — when selected, the
/// user types their own service title and the description becomes required
/// so staff have enough detail to assign a provider manually.
const String _otherServiceTitleValue = '__other__';

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otherTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _budgetController = TextEditingController();
  final _remarksController = TextEditingController();

  Category? _category;
  Color _accentColor = kPrimaryColor;
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

    final args = ModalRoute.of(context)!.settings.arguments as ServiceRequestFormArgs;
    _category = args.category;
    _accentColor = args.color;

    final user = context.read<AuthProvider>().currentUser;
    _contactPersonController.text = user?.username ?? '';
    _contactNoController.text = user?.mobileNo ?? '';

    // didChangeDependencies() runs during the build phase, so calling these
    // synchronously here would notify listeners (via each provider's
    // synchronous pre-await notifyListeners()) while the tree is still
    // building. Defer to after the current frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ServiceTitleProvider>().loadServiceTitles(_category!.id);

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
    });
  }

  bool get _isOtherServiceTitle => _selectedServiceTitle == _otherServiceTitleValue;

  @override
  void dispose() {
    _otherTitleController.dispose();
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
      serviceTitle: _isOtherServiceTitle ? _otherTitleController.text.trim() : _selectedServiceTitle!,
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
    final titleState = context.watch<ServiceTitleProvider>();

    return AuthCardScaffold(
      title: _category?.name ?? 'Service Request',
      subtitle: 'Fill in the details to request this service',
      avatarIcon: Icons.assignment_outlined,
      accentColor: _accentColor,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (addressState.loading)
              const Center(child: CircularProgressIndicator())
            else if (addressState.addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No saved addresses', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Add an address to continue', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(AddAddressScreen.routeName),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              )
            else ...[
              authFieldLabel('Service Address'),
              ThemedDropdownField<ClientAddress>(
                value: _selectedAddress,
                hint: 'Select an address',
                items: addressState.addresses
                    .map((a) => ThemedDropdownItem(value: a, label: '${a.addressTitle} - ${a.area}, ${a.city}'))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAddress = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 20),
            authFieldLabel('Service Title'),
            if (titleState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ThemedDropdownField<String>(
                value: _selectedServiceTitle,
                hint: 'Select a service title',
                items: [
                  ...titleState.serviceTitles.map((t) => ThemedDropdownItem(value: t.title, label: t.title)),
                  const ThemedDropdownItem(value: _otherServiceTitleValue, label: 'Other (not listed)'),
                ],
                onChanged: (v) => setState(() => _selectedServiceTitle = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            if (_isOtherServiceTitle) ...[
              const SizedBox(height: 20),
              authFieldLabel('Specify Service'),
              TextFormField(
                controller: _otherTitleController,
                decoration: authFieldDecoration(hint: 'What job do you need done?'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 20),
            authFieldLabel(_isOtherServiceTitle ? 'Service Description' : 'Service Description (optional)'),
            TextFormField(
              controller: _descriptionController,
              decoration: authFieldDecoration(hint: 'Describe what you need'),
              minLines: 2,
              maxLines: 4,
              validator: _isOtherServiceTitle
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Please describe the job so staff can assign a provider' : null
                  : null,
            ),
            const SizedBox(height: 20),
            Material(
              type: MaterialType.card,
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Mark as Urgent', style: TextStyle(fontWeight: FontWeight.w600)),
                value: _isUrgent,
                activeThumbColor: _accentColor,
                onChanged: (v) => setState(() => _isUrgent = v),
              ),
            ),
            const SizedBox(height: 20),
            authFieldLabel('Contact Person'),
            TextFormField(
              controller: _contactPersonController,
              decoration: authFieldDecoration(hint: 'Enter contact person name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Contact Number'),
            TextFormField(
              controller: _contactNoController,
              keyboardType: TextInputType.phone,
              decoration: authFieldDecoration(hint: 'Enter contact number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Estimated Budget (optional)'),
            TextFormField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: authFieldDecoration(hint: 'Enter estimated budget'),
            ),
            const SizedBox(height: 20),
            authFieldLabel('Remarks (optional)'),
            TextFormField(
              controller: _remarksController,
              decoration: authFieldDecoration(hint: 'Any additional remarks'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            authFieldLabel('Preferred Date & Time (optional)'),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    icon: Icons.calendar_today,
                    label: _selectedDate == null ? 'Preferred Date' : DateFormat.yMMMd().format(_selectedDate!),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    icon: Icons.access_time,
                    label: _selectedTime == null ? 'Preferred Time' : _selectedTime!.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            AuthPrimaryButton(label: 'Submit Request', isLoading: saving, onPressed: _submit, color: _accentColor),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.black87), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
