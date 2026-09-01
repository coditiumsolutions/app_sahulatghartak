import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer_service_request.dart';
import '../providers/customer_service_request_provider.dart';
import '../utils/api_error.dart';
import '../utils/cancel_reasons.dart';
import '../utils/constants.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/reason_dialog.dart';

const _brandDark = Color(0xFF0A4FA8);
const _brandBlue = Color(0xFF016EE3);
const _brandAccent = Color(0xFF4FC3F7);

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'inprogress':
      return Colors.blue;
    default:
      return Colors.orange;
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Icons.check_circle_rounded;
    case 'cancelled':
      return Icons.cancel_rounded;
    case 'inprogress':
      return Icons.sync_rounded;
    default:
      return Icons.hourglass_top_rounded;
  }
}

bool _canCancel(String status) => status.toLowerCase() == 'pending';

bool _canDelete(String status) {
  final normalized = status.toLowerCase();
  return normalized == 'cancelled' || normalized == 'completed';
}

Future<void> _callNumber(BuildContext context, String mobileNo) async {
  final uri = Uri(scheme: 'tel', path: mobileNo);
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start a call.')));
  }
}

/// Read-only detail view for a single service request. Accepts either the
/// already-fetched [request] (fast path from the list screen) or a
/// [requestUid] to fetch fresh via GET /customer-service-requests/{id}.
class RequestDetailScreen extends StatefulWidget {
  static const routeName = '/service-requests/detail';

  final CustomerServiceRequest? request;
  final int? requestUid;

  /// When set (i.e. hosted inside an [OpenContainer]), the back button calls
  /// this instead of [Navigator.maybePop] so the closing transform animation
  /// plays instead of a plain route pop.
  final VoidCallback? onClose;

  const RequestDetailScreen(
      {super.key, this.request, this.requestUid, this.onClose})
      : assert(request != null || requestUid != null);

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  CustomerServiceRequest? _request;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    if (_request == null) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    final uid = widget.requestUid ?? widget.request!.uid;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fetched = await context
          .read<CustomerServiceRequestProvider>()
          .fetchRequestById(uid);
      if (!mounted) return;
      setState(() => _request = fetched);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelRequest() async {
    final request = _request;
    if (request == null) return;

    final reason = await showReasonDialog(
      context,
      title: 'Cancel Request',
      message: 'Are you sure you want to cancel "${request.serviceTitle}"?',
      confirmLabel: 'Yes, Cancel',
      reasons: kCustomerCancelReasons,
      icon: Icons.cancel_outlined,
      color: Colors.orange,
    );
    if (reason == null || !mounted) return;

    final requestProvider = context.read<CustomerServiceRequestProvider>();
    final success = await requestProvider.cancelRequest(request, reason: reason);
    if (!mounted) return;

    if (success) {
      final updated = requestProvider.requests.firstWhere((r) => r.uid == request.uid, orElse: () => request);
      setState(() => _request = updated);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Request cancelled' : (requestProvider.error ?? 'Failed to cancel request'))),
    );
  }

  Future<void> _showPasscode() async {
    final request = _request;
    if (request == null) return;

    var passcode = request.passcode;
    passcode ??= await context.read<CustomerServiceRequestProvider>().getStoredPasscode(request.uid);
    if (!mounted) return;

    if (passcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passcode not available yet.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => _PasscodeDialog(passcode: passcode!),
    );
  }

  Future<void> _deleteRequest() async {
    final request = _request;
    if (request == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Request',
      message: 'Are you sure you want to delete "${request.serviceTitle}"? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      color: Colors.red,
    );
    if (confirmed != true || !mounted) return;

    final requestProvider = context.read<CustomerServiceRequestProvider>();
    final success = await requestProvider.deleteRequest(request.uid);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request deleted')));
      (widget.onClose ?? () => Navigator.of(context).maybePop())();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(requestProvider.error ?? 'Failed to delete request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final requestState = context.watch<CustomerServiceRequestProvider>();
    final cancelling = request != null && requestState.cancellingUid == request.uid;
    final deleting = request != null && requestState.deletingUid == request.uid;

    return PopScope(
      canPop: widget.onClose == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onClose?.call();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: request == null
            ? _LoadingOrErrorBody(
                loading: _loading,
                error: _error,
                onRetry: _fetch,
                onClose: widget.onClose)
            : SafeArea(
                top: false,
                child: RefreshIndicator(
                onRefresh: _fetch,
                child: CustomScrollView(
                  slivers: [
                    _DetailHeader(request: request, onClose: widget.onClose),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionCard(
                              title: 'Service Details',
                              icon: Icons.build_rounded,
                              children: [
                                _DetailRow(
                                    label: 'Category',
                                    value: request.categoryName,
                                    icon: Icons.category_rounded),
                                _DetailRow(
                                  label: 'Description',
                                  value:
                                      request.serviceDescription.trim().isEmpty
                                          ? 'No description provided'
                                          : request.serviceDescription,
                                  icon: Icons.notes_rounded,
                                  muted:
                                      request.serviceDescription.trim().isEmpty,
                                ),
                                if (request.isUrgent)
                                  _DetailRow(
                                    label: 'Priority',
                                    icon: Icons.priority_high_rounded,
                                    valueWidget: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color:
                                              Colors.red.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Text('Urgent',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SectionCard(
                              title: 'Schedule & Location',
                              icon: Icons.event_note_rounded,
                              children: [
                                _DetailRow(
                                  label: 'Preferred Date',
                                  value: request.preferredServiceDate.isEmpty
                                      ? 'Not specified'
                                      : request.preferredServiceDate,
                                  icon: Icons.calendar_today_rounded,
                                  muted: request.preferredServiceDate.isEmpty,
                                ),
                                _DetailRow(
                                  label: 'Preferred Time',
                                  value: request.preferredServiceTime.isEmpty
                                      ? 'Not specified'
                                      : request.preferredServiceTime,
                                  icon: Icons.access_time_rounded,
                                  muted: request.preferredServiceTime.isEmpty,
                                ),
                                _DetailRow(
                                    label: 'Address',
                                    value: request.addressTitle,
                                    icon: Icons.location_on_rounded),
                              ],
                            ),
                            if (request.providerUid != null) ...[
                              const SizedBox(height: 14),
                              _SectionCard(
                                title: 'Provider Details',
                                icon: Icons.engineering_rounded,
                                children: [
                                  if (request.providerName != null)
                                    _DetailRow(
                                      label: 'Name',
                                      icon: Icons.badge_rounded,
                                      valueWidget: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: const Color(0xFFF6F8FC),
                                            backgroundImage: request.providerProfilePhotoPath != null
                                                ? NetworkImage('$kApiFileBaseUrl/${request.providerProfilePhotoPath!}')
                                                : null,
                                            child: request.providerProfilePhotoPath == null
                                                ? Icon(Icons.person_rounded, size: 18, color: kPrimaryColor)
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              request.providerName!,
                                              style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (request.providerMobileNo != null)
                                    _DetailRow(
                                      label: 'Contact Number',
                                      icon: Icons.phone_rounded,
                                      valueWidget: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              request.providerMobileNo!,
                                              style: const TextStyle(color: Color(0xFF1A2233), fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), visualDensity: VisualDensity.compact),
                                            onPressed: () => _callNumber(context, request.providerMobileNo!),
                                            icon: Icon(Icons.call_rounded, size: 16, color: _brandBlue),
                                            label: Text('Call', style: TextStyle(color: _brandBlue, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  _DetailRow(label: 'Provider ID', value: '#${request.providerUid}', icon: Icons.badge_outlined),
                                  if (request.providerCnic != null)
                                    _DetailRow(label: 'CNIC No', value: request.providerCnic!, icon: Icons.credit_card_rounded),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _brandBlue,
                                        side: BorderSide(color: _brandBlue.withValues(alpha: 0.4)),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: _showPasscode,
                                      icon: const Icon(Icons.password_rounded, size: 18),
                                      label: const Text('Show Passcode', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            _SectionCard(
                              title: 'Contact Information',
                              icon: Icons.person_rounded,
                              children: [
                                _DetailRow(
                                    label: 'Contact Person',
                                    value: request.contactPerson,
                                    icon: Icons.badge_rounded),
                                _DetailRow(
                                    label: 'Contact Number',
                                    value: request.contactNo,
                                    icon: Icons.phone_rounded),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SectionCard(
                              title: 'Budget & Remarks',
                              icon: Icons.payments_rounded,
                              children: [
                                _DetailRow(
                                  label: 'Estimated Budget',
                                  value: request.estimatedBudget > 0
                                      ? 'Rs. ${request.estimatedBudget.toStringAsFixed(0)}'
                                      : 'Not specified',
                                  icon: Icons.account_balance_wallet_rounded,
                                  muted: request.estimatedBudget <= 0,
                                ),
                                _DetailRow(
                                  label: 'Remarks',
                                  value: (request.remarks == null ||
                                          request.remarks!.trim().isEmpty)
                                      ? 'No remarks'
                                      : request.remarks!,
                                  icon: Icons.comment_rounded,
                                  muted: request.remarks == null ||
                                      request.remarks!.trim().isEmpty,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SectionCard(
                              title: 'Request Info',
                              icon: Icons.info_outline_rounded,
                              children: [
                                _DetailRow(
                                    label: 'Request ID',
                                    value: '#${request.uid}',
                                    icon: Icons.tag_rounded),
                                _DetailRow(
                                  label: 'Requested On',
                                  value: DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(request.createdOn),
                                  icon: Icons.schedule_rounded,
                                ),
                              ],
                            ),
                            if (_canCancel(request.status) || _canDelete(request.status)) ...[
                              const SizedBox(height: 20),
                              if (_canCancel(request.status))
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: kProminentOutlinedButtonStyle(Colors.orange).copyWith(
                                      side: WidgetStateProperty.all(const BorderSide(color: Colors.orange, width: 2)),
                                    ),
                                    onPressed: cancelling ? null : _cancelRequest,
                                    icon: cancelling
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                                        : const Icon(Icons.cancel_outlined),
                                    label: Text(cancelling ? 'Cancelling…' : 'Cancel Request'),
                                  ),
                                ),
                              if (_canCancel(request.status) && _canDelete(request.status)) const SizedBox(height: 12),
                              if (_canDelete(request.status))
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: kProminentFilledButtonStyle(Colors.red),
                                    onPressed: deleting ? null : _deleteRequest,
                                    icon: deleting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.delete_outline_rounded),
                                    label: Text(deleting ? 'Deleting…' : 'Delete Request'),
                                  ),
                                ),
                            ],
                          ],
                        ),
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

class _LoadingOrErrorBody extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback? onClose;

  const _LoadingOrErrorBody(
      {required this.loading,
      required this.error,
      required this.onRetry,
      this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onClose ?? () => Navigator.of(context).maybePop()),
            ),
          ),
          Expanded(
            child: Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(error ?? 'Failed to load request',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: onRetry, child: const Text('Retry')),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient header mirroring [_RequestsBanner] from the list screen, with the
/// service title, status pill, and a back button — collapses on scroll via
/// [SliverAppBar].
class _DetailHeader extends StatelessWidget {
  final CustomerServiceRequest request;
  final VoidCallback? onClose;
  const _DetailHeader({required this.request, this.onClose});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);

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
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_brandDark, _brandBlue]),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _brandAccent.withValues(alpha: 0.14)),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -16,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06)),
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
                            request.serviceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                height: 1.1),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(request.status),
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(request.status,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11)),
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
        child: Container(height: 3, color: statusColor),
      ),
    );
  }
}

/// A titled white card grouping related [_DetailRow]s — keeps room for more
/// sections (e.g. assigned provider, timeline) to be appended later.
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _brandDark.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: _brandBlue),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: Color(0xFF1A2233))),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 14),
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

  const _DetailRow(
      {required this.label,
      this.value,
      this.valueWidget,
      required this.icon,
      this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 15, color: kPrimaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value ?? '',
                      style: TextStyle(
                        color:
                            muted ? Colors.grey[400] : const Color(0xFF1A2233),
                        fontSize: 14,
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

/// Read-only display of the completion passcode the customer must give the
/// provider to mark the job done — mirrors the branded look of
/// [showConfirmDialog] but with a single "Close" action.
class _PasscodeDialog extends StatelessWidget {
  final String passcode;

  const _PasscodeDialog({required this.passcode});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _brandBlue.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.password_rounded, color: _brandBlue, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Completion Passcode',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2233), letterSpacing: -0.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code with your provider once the job is finished so they can mark it complete.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.4, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: const Color(0xFFF6F8FC), borderRadius: BorderRadius.circular(14)),
                child: Text(
                  passcode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _brandDark, letterSpacing: 8),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
