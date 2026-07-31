import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/service.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends StatefulWidget {
  static const routeName = '/booking';
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _mobileCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Service? _service;

  @override
  void dispose() {
    _nameCtl.dispose();
    _mobileCtl.dispose();
    _addressCtl.dispose();
    _cityCtl.dispose();
    _notesCtl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is Service) _service = arg;

    return Scaffold(
      appBar: AppBar(title: Text(_service?.name ?? 'Booking'), backgroundColor: Colors.yellow),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Customer Name'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(controller: _mobileCtl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(controller: _addressCtl, decoration: const InputDecoration(labelText: 'Address'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(controller: _cityCtl, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _pickDate, child: Text(_selectedDate == null ? 'Select Date' : DateFormat.yMMMd().format(_selectedDate!)))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: _pickTime, child: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)))),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: _notesCtl, decoration: const InputDecoration(labelText: 'Notes'), minLines: 2, maxLines: 4),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: const Text('Confirm Booking'))),
          ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time')));
      return;
    }

    final booking = Booking(
      customerName: _nameCtl.text.trim(),
      mobile: _mobileCtl.text.trim(),
      address: _addressCtl.text.trim(),
      city: _cityCtl.text.trim(),
      serviceName: _service?.name ?? 'Service',
      serviceDate: _selectedDate!.toIso8601String(),
      serviceTime: _selectedTime!.format(context),
      notes: _notesCtl.text.trim(),
    );

    await context.read<BookingProvider>().addBooking(booking);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed')));
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
