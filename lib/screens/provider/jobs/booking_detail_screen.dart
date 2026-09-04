import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/provider/service_booking.dart';
import '../../../providers/provider_bookings_provider.dart';
import '../../../utils/cancel_reasons.dart';
import '../../../utils/constants.dart';
import '../../../utils/status_progress.dart';
import '../../../widgets/reason_dialog.dart';
import '../../../widgets/status_progress_bar.dart';
import '../../../widgets/themed_dropdown.dart';

const _brandDark = Color(0xFF0A4FA8);
const _brandBlue = Color(0xFF016EE3);
const _brandAccent = Color(0xFF4FC3F7);

Color statusColor(String status) {
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

IconData statusIcon(String status) {
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

/// Full-screen booking detail, opened via container-transform from the
/// bookings list — mirrors [RequestDetailScreen]'s gradient header + sectioned
/// card layout, with the provider-side accept/reject/complete actions pinned
/// to the bottom instead of a bottom-sheet.
class BookingDetailScreen extends StatefulWidget {
  final ServiceBooking booking;
  final VoidCallback? onClose;

  /// When true, hides all accept/reject/cancel/complete actions and shows
  /// only the booking's details — used for stale records like rejected
  /// requests that the provider can no longer act on.
  final bool readOnly;

  const BookingDetailScreen({super.key, required this.booking, this.onClose, this.readOnly = false});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Background refresh, even though we already have widget.booking as a
    // snapshot from the list — the list itself may be stale (loaded once,
    // no polling). Merges into ProviderBookingsProvider.bookings on success,
    // so this screen (via context.watch in build) and the list both pick it
    // up. Best-effort: on failure we just keep showing the cached snapshot.
    context.read<ProviderBookingsProvider>().fetchBookingById(widget.booking.uid, widget.booking.providerUid).catchError((_) => widget.booking);
  }

  /// The freshest known copy of this booking — from the shared provider
  /// list if present there (kept current by every action below plus the
  /// background refresh in [initState]), falling back to the snapshot this
  /// screen was opened with (e.g. read-only/rejected bookings, which aren't
  /// kept in the main list).
  ServiceBooking get _currentBooking =>
      context.read<ProviderBookingsProvider>().bookings.firstWhere((b) => b.uid == widget.booking.uid, orElse: () => widget.booking);

  Future<void> _submit(String status, {String? reason}) async {
    setState(() => _submitting = true);
    final provider = context.read<ProviderBookingsProvider>();
    final booking = _currentBooking;
    final success = await provider.updateStatus(booking, status, customerPaid: booking.customerPaid, reason: reason);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final message = success ? 'Booking marked as $status' : (provider.error ?? 'Failed to update booking');
    if (success) {
      (widget.onClose ?? () => Navigator.of(context).maybePop())();
    } else {
      setState(() => _submitting = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startJob() async {
    setState(() => _submitting = true);
    final provider = context.read<ProviderBookingsProvider>();
    final success = await provider.startJob(_currentBooking);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final message = success ? 'Job started' : (provider.error ?? 'Failed to start job');
    if (success) {
      (widget.onClose ?? () => Navigator.of(context).maybePop())();
    } else {
      setState(() => _submitting = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _respond(bool accept, {String? reason}) async {
    setState(() => _submitting = true);
    final provider = context.read<ProviderBookingsProvider>();
    final success = await provider.respond(_currentBooking, accept, reason: reason);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final message = success ? (accept ? 'Booking accepted' : 'Booking rejected') : (provider.error ?? 'Failed to respond to booking');
    if (success) {
      (widget.onClose ?? () => Navigator.of(context).maybePop())();
    } else {
      setState(() => _submitting = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmReject() async {
    final reason = await showReasonDialog(
      context,
      title: 'Reject Booking',
      message: 'Are you sure you want to reject this booking for "${_currentBooking.requestTitle}"? This cannot be undone.',
      confirmLabel: 'Yes, Reject',
      reasons: kProviderCancelReasons,
      icon: Icons.cancel_outlined,
      color: Colors.red,
    );
    if (reason == null || !mounted) return;
    await _respond(false, reason: reason);
  }

  Future<void> _confirmCancel() async {
    final reason = await showReasonDialog(
      context,
      title: 'Cancel Booking',
      message: 'Are you sure you want to cancel this booking for "${_currentBooking.requestTitle}"? This cannot be undone.',
      confirmLabel: 'Yes, Cancel',
      reasons: kProviderCancelReasons,
      icon: Icons.cancel_outlined,
      color: Colors.red,
    );
    if (reason == null || !mounted) return;
    await _submit('Cancelled', reason: reason);
  }

  Future<void> _openCompletionDialog() async {
    final provider = context.read<ProviderBookingsProvider>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _CompletionDialog(booking: _currentBooking, provider: provider),
    );
    if (result == true && mounted) {
      (widget.onClose ?? () => Navigator.of(context).maybePop())();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<ProviderBookingsProvider>().bookings.firstWhere((b) => b.uid == widget.booking.uid, orElse: () => widget.booking);
    final isPending = !widget.readOnly && booking.status == 'Pending';
    final isAccepted = !widget.readOnly && booking.status == 'Accepted';
    final canComplete = !widget.readOnly && (booking.status == 'Accepted' || booking.status == 'In Progress');

    return PopScope(
      canPop: widget.onClose == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onClose?.call();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: CustomScrollView(
          slivers: [
            _DetailHeader(booking: booking, onClose: widget.onClose),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: statusColor(booking.status).withValues(alpha: 0.35), width: 1.2),
                      ),
                      child: StatusProgressBar(
                        steps: kBookingStatusSteps,
                        currentStep: bookingStatusStep(booking.status),
                        activeColor: statusColor(booking.status),
                        terminalLabel: isBookingStatusTerminal(booking.status) ? '${booking.status} Booking' : null,
                        terminalColor: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Client',
                      icon: Icons.person_rounded,
                      children: [
                        _DetailRow(label: 'Name', value: booking.clientName, icon: Icons.badge_rounded),
                        if (booking.clientMobileNo != null)
                          _DetailRow(
                            label: 'Contact Number',
                            icon: Icons.phone_rounded,
                            valueWidget: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.clientMobileNo!,
                                    style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
                                  onPressed: () => _callNumber(context, booking.clientMobileNo!),
                                  icon: const Icon(Icons.call_rounded, size: 16, color: kAccentColor),
                                  label: const Text('Call', style: TextStyle(color: kAccentColor, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        _DetailRow(
                          label: booking.clientAddressTitle ?? 'Job Site',
                          icon: Icons.location_on_rounded,
                          value: [booking.clientFullAddress, booking.clientArea, booking.clientCity].whereType<String>().join(', '),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Service Details',
                      icon: Icons.build_rounded,
                      children: [
                        _DetailRow(label: 'Request', value: booking.requestTitle, icon: Icons.assignment_rounded),
                        _DetailRow(
                          label: 'Details',
                          value: booking.serviceDetail.trim().isEmpty ? 'No details provided' : booking.serviceDetail,
                          icon: Icons.notes_rounded,
                          muted: booking.serviceDetail.trim().isEmpty,
                        ),
                        if (booking.passcode != null)
                          _DetailRow(label: 'Completion Passcode', value: booking.passcode!, icon: Icons.password_rounded),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Payment',
                      icon: Icons.payments_rounded,
                      children: [
                        _DetailRow(label: 'Final Amount', value: 'Rs ${booking.finalAmount.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded),
                        _DetailRow(label: 'Customer Paid', value: 'Rs ${booking.customerPaid.toStringAsFixed(0)}', icon: Icons.receipt_rounded),
                        _DetailRow(label: 'Payment Mode', value: booking.paymentMode, icon: Icons.credit_card_rounded),
                        _DetailRow(label: 'Your Earning', value: 'Rs ${booking.providerEarning.toStringAsFixed(0)}', icon: Icons.savings_rounded),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Booking Info',
                      icon: Icons.info_outline_rounded,
                      compact: true,
                      children: [
                        _DetailRow(label: 'Booking ID', value: '#${booking.uid}', icon: Icons.tag_rounded, compact: true),
                        _DetailRow(
                            label: 'Created On',
                            value: DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdOn),
                            icon: Icons.schedule_rounded,
                            compact: true),
                        if (booking.acceptedOn != null)
                          _DetailRow(
                              label: 'Accepted On',
                              value: DateFormat('dd MMM yyyy, hh:mm a').format(booking.acceptedOn!),
                              icon: Icons.thumb_up_rounded,
                              compact: true),
                        if (booking.completedOn != null)
                          _DetailRow(
                              label: 'Completed On',
                              value: DateFormat('dd MMM yyyy, hh:mm a').format(booking.completedOn!),
                              icon: Icons.check_circle_rounded,
                              compact: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isPending)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: kProminentOutlinedButtonStyle(Colors.red),
                              onPressed: _submitting ? null : _confirmReject,
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                    else if (isAccepted)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: kProminentOutlinedButtonStyle(Colors.red),
                              onPressed: _submitting ? null : _confirmCancel,
                              child: const Text('Cancel Booking'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: kProminentFilledButtonStyle(kAccentColor),
                              onPressed: _submitting ? null : _startJob,
                              icon: _submitting
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.play_arrow_rounded, size: 18),
                              label: Text(_submitting ? 'Starting…' : 'Start Job'),
                            ),
                          ),
                        ],
                      )
                    else if (canComplete)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: kProminentOutlinedButtonStyle(Colors.red),
                              onPressed: _submitting ? null : _confirmCancel,
                              child: const Text('Cancel Booking'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: kProminentFilledButtonStyle(kPrimaryColor),
                              onPressed: _submitting ? null : _openCompletionDialog,
                              child: const Text('Mark Completed'),
                            ),
                          ),
                        ],
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Booking ${booking.status}', style: TextStyle(color: statusColor(booking.status), fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final ServiceBooking booking;
  final VoidCallback? onClose;
  const _DetailHeader({required this.booking, this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(booking.status);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 104,
      backgroundColor: _brandDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onClose ?? () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_brandDark, _brandBlue]),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _brandAccent.withValues(alpha: 0.14)),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -16,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            booking.requestTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.2, height: 1.1),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon(booking.status), size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(booking.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(height: 3, color: color),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool compact;

  const _SectionCard({required this.title, required this.icon, required this.children, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      padding: EdgeInsets.fromLTRB(compact ? 14 : 16, compact ? 10 : 14, compact ? 14 : 16, compact ? 4 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 14 : 17, color: compact ? Colors.grey[500] : _brandBlue),
              SizedBox(width: compact ? 6 : 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : 14.5,
                      color: compact ? Colors.grey[600] : const Color(0xFF1A2233))),
            ],
          ),
          SizedBox(height: compact ? 4 : 6),
          Divider(height: compact ? 10 : 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData icon;
  final bool muted;
  final bool compact;

  const _DetailRow({required this.label, this.value, this.valueWidget, required this.icon, this.muted = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final boxSize = compact ? 22.0 : 30.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF6F8FC), borderRadius: BorderRadius.circular(compact ? 6 : 9)),
            child: Icon(icon, size: compact ? 11 : 15, color: kPrimaryColor),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: compact ? 10 : 11.5, fontWeight: FontWeight.w600)),
                SizedBox(height: compact ? 1 : 2),
                valueWidget ??
                    Text(
                      value ?? '',
                      style: TextStyle(
                        color: muted ? Colors.grey[400] : const Color(0xFF1A2233),
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
              ],
            ),
          ),
        ],
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
    if (passcode.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid passcode and an amount greater than 0 to close this job.');
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_brandDark, _brandBlue]),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Complete Job', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                            SizedBox(height: 2),
                            Text('Verify with the customer to finish up', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel(icon: Icons.password_rounded, text: 'Passcode from customer'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passcodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 4),
                        decoration: _dialogFieldDecoration(
                          hint: '••••',
                          hintStyle: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _FieldLabel(icon: Icons.payments_rounded, text: 'Amount collected (Rs) *'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        decoration: _dialogFieldDecoration(hint: '0'),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel(icon: Icons.credit_card_rounded, text: 'Payment mode'),
                      const SizedBox(height: 2),
                      Text('Set by staff: ${booking.paymentMode}', style: TextStyle(color: Colors.grey[500], fontSize: 11.5, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      ThemedDropdownField<String?>(
                        value: _paymentModeOverride,
                        items: const [
                          ThemedDropdownItem(value: null, label: 'Keep existing'),
                          ThemedDropdownItem(value: 'CashToProvider', label: 'Cash to Provider'),
                          ThemedDropdownItem(value: 'OnlineToCompany', label: 'Online to Company'),
                        ],
                        onChanged: (value) => setState(() => _paymentModeOverride = value),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: kProminentOutlinedButtonStyle(Colors.grey.shade400).copyWith(
                                foregroundColor: WidgetStateProperty.all(Colors.grey.shade700),
                                side: WidgetStateProperty.all(BorderSide(color: Colors.grey.shade300, width: 1.5)),
                              ),
                              onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: kProminentFilledButtonStyle(kAccentColor),
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_rounded, size: 18),
                              label: Text(_submitting ? 'Submitting…' : 'Mark Completed'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _dialogFieldDecoration({String? hint, TextStyle? hintStyle}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: hintStyle,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF6F8FC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _brandBlue, width: 1.5)),
    counterText: '',
  );
}

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FieldLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _brandBlue),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2233))),
      ],
    );
  }
}
