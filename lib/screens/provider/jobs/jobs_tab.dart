import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/service_booking.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_bookings_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/provider/status_chip.dart';
import '../../../widgets/provider/tab_state_placeholder.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.blueGrey;
    case 'Accepted':
      return Colors.orange;
    case 'In Progress':
      return kAccentColor;
    case 'Closed':
    case 'Completed':
      return Colors.green;
    case 'Cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

bool _isFinalized(String status) => status == 'Closed' || status == 'Completed' || status == 'Cancelled';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
  }

  void _loadBookings() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      context.read<ProviderBookingsProvider>().loadBookings(providerUid);
    }
  }

  void _openBookingDetail(ServiceBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _BookingDetailSheet(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderBookingsProvider>();
    final bookings = provider.bookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'My Bookings',
        subtitle: bookings.isEmpty ? 'No bookings yet' : '${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
      ),
      body: provider.loading && bookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && bookings.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async => _loadBookings(),
                  child: TabStatePlaceholder(
                    icon: Icons.wifi_off_rounded,
                    color: Colors.red,
                    title: 'Couldn\'t load bookings',
                    message: provider.error,
                    onRetry: _loadBookings,
                  ),
                )
              : bookings.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () async => _loadBookings(),
                      child: const TabStatePlaceholder(
                        icon: Icons.work_outline_rounded,
                        color: kPrimaryColor,
                        title: 'No bookings yet',
                        message: 'Bookings appear here once you accept a service request from a customer.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadBookings(),
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return _BookingGridTile(booking: booking, onTap: () => _openBookingDetail(booking));
                        },
                      ),
                    ),
    );
  }
}

class _BookingGridTile extends StatelessWidget {
  final ServiceBooking booking;
  final VoidCallback onTap;

  const _BookingGridTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.requestTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A2233))),
            const SizedBox(height: 4),
            Text(booking.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            StatusChip(label: booking.status, color: statusColor),
            const SizedBox(height: 8),
            Text('Rs ${booking.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: kPrimaryColor)),
          ],
        ),
      ),
    );
  }
}

class _BookingDetailSheet extends StatefulWidget {
  final ServiceBooking booking;

  const _BookingDetailSheet({required this.booking});

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  late final TextEditingController _amountController;
  final _passcodeController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.booking.customerPaid.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _submit(String status) async {
    setState(() => _submitting = true);

    final provider = context.read<ProviderBookingsProvider>();
    final amount = double.tryParse(_amountController.text.trim()) ?? widget.booking.customerPaid;
    final success = await provider.updateStatus(widget.booking, status, customerPaid: amount);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final message = success ? 'Booking marked as $status' : (provider.error ?? 'Failed to update booking');
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusColor = _statusColor(booking.status);
    final finalized = _isFinalized(booking.status);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(booking.requestTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  StatusChip(label: booking.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(booking.clientName, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              Text(booking.serviceDetail, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text('Final: Rs ${booking.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor)),
                  Text('Provider ID: ${booking.providerUid}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                enabled: !finalized,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (Rs)', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passcodeController,
                enabled: !finalized,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Passcode',
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: 'Coming soon - not yet verified by the server',
                ),
              ),
              const SizedBox(height: 20),
              if (finalized)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Booking ${booking.status}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: kProminentOutlinedButtonStyle(Colors.red),
                        onPressed: _submitting ? null : () => _submit('Cancelled'),
                        child: const Text('Cancel Booking'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: kProminentFilledButtonStyle(kPrimaryColor),
                        onPressed: _submitting ? null : () => _submit('Closed'),
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Mark as Closed'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
