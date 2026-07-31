import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer_service_request.dart';
import '../providers/customer_service_request_provider.dart';
import '../utils/constants.dart';

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
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

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
            : RefreshIndicator(
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
                          ],
                        ),
                      ),
                    ),
                  ],
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
