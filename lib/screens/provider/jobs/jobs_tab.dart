import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

IconData _statusIcon(String status) {
  switch (status) {
    case 'Pending':
      return Icons.hourglass_top_rounded;
    case 'Accepted':
      return Icons.thumb_up_rounded;
    case 'In Progress':
      return Icons.sync_rounded;
    case 'Closed':
    case 'Completed':
      return Icons.check_circle_rounded;
    case 'Cancelled':
      return Icons.cancel_rounded;
    default:
      return Icons.circle;
  }
}

Future<void> _callNumber(BuildContext context, String mobileNo) async {
  final uri = Uri(scheme: 'tel', path: mobileNo);
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start a call.')));
  }
}

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
    // Rejected bookings are staff-only and should never surface to the provider.
    final bookings = provider.bookings.where((b) => !b.isRejected).toList();

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
                          childAspectRatio: 0.82,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: statusColor.withValues(alpha: 0.12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: statusColor.withValues(alpha: 0.12), width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statusColor.withValues(alpha: 0.06), Colors.white],
            ),
            boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_statusIcon(booking.status), size: 17, color: statusColor),
                ),
                const SizedBox(height: 12),
                Text(booking.requestTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF12182B))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(booking.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Spacer(),
                StatusChip(label: booking.status, color: statusColor),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.payments_rounded, size: 14, color: kPrimaryColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text('Rs ${booking.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kPrimaryColor)),
                  ],
                ),
              ],
            ),
          ),
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
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.booking.customerPaid.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
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

  Future<void> _respond(bool accept) async {
    setState(() => _submitting = true);

    final provider = context.read<ProviderBookingsProvider>();
    final success = await provider.respond(widget.booking, accept);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final message = success
        ? (accept ? 'Booking accepted' : 'Booking rejected')
        : (provider.error ?? 'Failed to respond to booking');
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCompletionDialog() async {
    final provider = context.read<ProviderBookingsProvider>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CompletionDialog(booking: widget.booking, provider: provider),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusColor = _statusColor(booking.status);
    final isPending = booking.status == 'Pending';
    final canComplete = booking.status == 'Accepted' || booking.status == 'In Progress';

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
              if (booking.clientFullAddress != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.clientAddressTitle ?? 'Job Site',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                booking.clientFullAddress,
                                booking.clientArea,
                                booking.clientCity,
                              ].whereType<String>().join(', '),
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (booking.clientMobileNo != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: kProminentOutlinedButtonStyle(kAccentColor),
                  onPressed: () => _callNumber(context, booking.clientMobileNo!),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call Client'),
                ),
              ],
              const SizedBox(height: 20),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: kProminentOutlinedButtonStyle(Colors.red),
                        onPressed: _submitting ? null : () => _respond(false),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: kProminentFilledButtonStyle(kAccentColor),
                        onPressed: _submitting ? null : () => _respond(true),
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                )
              else if (canComplete) ...[
                if (booking.passcode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Passcode for customer: ${booking.passcode}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
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
                        onPressed: _submitting ? null : _openCompletionDialog,
                        child: const Text('Mark Completed'),
                      ),
                    ),
                  ],
                ),
              ] else
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Booking ${booking.status}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionDialog extends StatefulWidget {
  final ServiceBooking booking;
  final ProviderBookingsProvider provider;

  const _CompletionDialog({required this.booking, required this.provider});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  late final TextEditingController _passcodeController;
  late final TextEditingController _amountController;
  String? _paymentModeOverride;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passcodeController = TextEditingController();
    _amountController = TextEditingController(text: widget.booking.finalAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final passcode = _passcodeController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (passcode.isEmpty || amount == null) {
      setState(() => _error = 'Enter a valid passcode and amount.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final success = await widget.provider.verifyCompletion(
      widget.booking,
      passcode: passcode,
      actualAmountPaid: amount,
      paymentMode: _paymentModeOverride,
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking marked as completed')));
    } else {
      setState(() {
        _submitting = false;
        _error = widget.provider.error ?? 'Failed to verify completion';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return AlertDialog(
      title: const Text('Complete Job'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _passcodeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Passcode', border: OutlineInputBorder(), isDense: true, counterText: ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount Collected (Rs)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            Text('Payment mode (set by staff: ${booking.paymentMode})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String?>(
              initialValue: _paymentModeOverride,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: null, child: Text('Keep existing')),
                DropdownMenuItem(value: 'CashToProvider', child: Text('Cash to Provider')),
                DropdownMenuItem(value: 'OnlineToCompany', child: Text('Online to Company')),
              ],
              onChanged: (value) => setState(() => _paymentModeOverride = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: kProminentFilledButtonStyle(kPrimaryColor),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }
}
