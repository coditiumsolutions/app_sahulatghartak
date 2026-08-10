import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer_service_request.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_service_request_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_placeholder.dart';
import 'request_detail_screen.dart';

class ServiceRequestsScreen extends StatefulWidget {
  static const routeName = '/service-requests';

  /// True when hosted inside [MainNavigationShell], which already provides
  /// the bottom navigation bar.
  final bool embedded;

  const ServiceRequestsScreen({super.key, this.embedded = false});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  void _loadRequests() {
    final clientUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (clientUid != null) {
      context.read<CustomerServiceRequestProvider>().loadRequests(clientUid);
    }
  }

  bool _canDelete(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'cancelled' || normalized == 'completed';
  }

  bool _canCancel(String status) => status.toLowerCase() == 'pending';

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

  Future<void> _deleteRequest(CustomerServiceRequest request) async {
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

    final message = success
        ? 'Request deleted'
        : (requestProvider.error ?? 'Failed to delete request');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancelRequest(CustomerServiceRequest request) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel Request',
      message: 'Are you sure you want to cancel "${request.serviceTitle}"?',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'No',
      icon: Icons.cancel_outlined,
      color: Colors.orange,
    );
    if (confirmed != true || !mounted) return;

    final requestProvider = context.read<CustomerServiceRequestProvider>();
    final success = await requestProvider.cancelRequest(request);
    if (!mounted) return;

    final message = success
        ? 'Request cancelled'
        : (requestProvider.error ?? 'Failed to cancel request');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);
  static const _brandAccent = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    final requestState = context.watch<CustomerServiceRequestProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(128),
        child: _RequestsBanner(count: requestState.requests.length),
      ),
      bottomNavigationBar:
          widget.embedded ? null : const AppBottomNavigation(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: () async => _loadRequests(),
        child: requestState.loading
            ? const Center(child: CircularProgressIndicator())
            : requestState.error != null
                ? EmptyStatePlaceholder(
                    icon: Icons.wifi_off_rounded,
                    color: Colors.red,
                    title: 'Couldn\'t load requests',
                    message: requestState.error,
                    onRetry: _loadRequests,
                  )
                : requestState.requests.isEmpty
                    ? const EmptyStatePlaceholder(
                        icon: Icons.receipt_long_rounded,
                        color: kPrimaryColor,
                        title: 'No service requests yet',
                        message: 'Requests you submit will show up here so you can track their status.',
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: requestState.requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = requestState.requests[index];
                          final deleting =
                              requestState.deletingUid == request.uid;
                          final cancelling =
                              requestState.cancellingUid == request.uid;

                          return _RequestCard(
                            request: request,
                            statusColor: _statusColor(request.status),
                            canCancel: _canCancel(request.status),
                            canDelete: _canDelete(request.status),
                            cancelling: cancelling,
                            deleting: deleting,
                            onCancel: () => _cancelRequest(request),
                            onDelete: () => _deleteRequest(request),
                          );
                        },
                      ),
      ),
    );
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

/// A single service-request card: a colored left rail signals status at a
/// glance, icon-led rows keep address/schedule/budget scannable, and the
/// status pill + urgent flag are pulled into the header for quick triage.
class _RequestCard extends StatelessWidget {
  final CustomerServiceRequest request;
  final Color statusColor;
  final bool canCancel;
  final bool canDelete;
  final bool cancelling;
  final bool deleting;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _RequestCard({
    required this.request,
    required this.statusColor,
    required this.canCancel,
    required this.canDelete,
    required this.cancelling,
    required this.deleting,
    required this.onCancel,
    required this.onDelete,
  });

  /// Completed/cancelled requests are done and no longer interactable (aside
  /// from deleting them), so they get a compact single-row treatment instead
  /// of the full card — freeing screen space for requests still in play.
  bool get _isCompact {
    final normalized = request.status.toLowerCase();
    return normalized == 'completed' || normalized == 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: const Color(0xFFF4F7FB),
      closedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      transitionDuration: const Duration(milliseconds: 420),
      closedBuilder: (context, openContainer) {
        if (_isCompact) {
          return _buildCompactCard(context, openContainer);
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0A4FA8).withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: openContainer,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.serviceTitle,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16.5,
                                          color: Color(0xFF1A2233),
                                          height: 1.2),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      request.categoryName,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_statusIcon(request.status),
                                        size: 13, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(request.status,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (request.serviceDescription.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              request.serviceDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13.5,
                                  height: 1.35),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FC),
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(
                                    icon: Icons.location_on_rounded,
                                    text: request.addressTitle),
                                const SizedBox(height: 6),
                                _InfoRow(
                                  icon: Icons.event_rounded,
                                  text:
                                      '${request.preferredServiceDate} · ${request.preferredServiceTime}',
                                  trailing: request.isUrgent
                                      ? Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.priority_high_rounded,
                                                  size: 12, color: Colors.red),
                                              Text('Urgent',
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ],
                                          ),
                                        )
                                      : null,
                                ),
                                if (request.estimatedBudget > 0) ...[
                                  const SizedBox(height: 6),
                                  _InfoRow(
                                      icon: Icons.payments_rounded,
                                      text:
                                          'Est. budget Rs. ${request.estimatedBudget.toStringAsFixed(0)}'),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 13, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Requested ${DateFormat('dd MMM yyyy').format(request.createdOn)}',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (canCancel || canDelete) ...[
                            const Divider(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (canCancel)
                                  cancelling
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2)))
                                      : TextButton.icon(
                                          style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              visualDensity:
                                                  VisualDensity.compact),
                                          onPressed: onCancel,
                                          icon: const Icon(
                                              Icons.cancel_outlined,
                                              size: 17,
                                              color: Colors.orange),
                                          label: const Text('Cancel',
                                              style: TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                if (canDelete)
                                  deleting
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2)))
                                      : TextButton.icon(
                                          style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              visualDensity:
                                                  VisualDensity.compact),
                                          onPressed: onDelete,
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 17,
                                              color: Colors.red),
                                          label: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                              ],
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
        );
      },
      openBuilder: (context, closeContainer) {
        return RequestDetailScreen(request: request, onClose: closeContainer);
      },
    );
  }

  Widget _buildCompactCard(BuildContext context, VoidCallback openContainer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0A4FA8).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openContainer,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                  child: Row(
                    children: [
                      Icon(_statusIcon(request.status), size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              request.serviceTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1A2233)),
                            ),
                            Text(
                              '${request.status} · ${DateFormat('dd MMM yyyy').format(request.createdOn)}',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      if (canDelete)
                        deleting
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : IconButton(
                                onPressed: onDelete,
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red),
                                tooltip: 'Delete',
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? trailing;

  const _InfoRow({required this.icon, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: kPrimaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Color(0xFF3A4658),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A gradient header replacing the flat default [AppBar] — mirrors the
/// brand gradient used on the landing/splash screens and dock, with a
/// decorative glow and a live request count.
class _RequestsBanner extends StatelessWidget {
  final int count;
  const _RequestsBanner({required this.count});

  static const _brandDark = _ServiceRequestsScreenState._brandDark;
  static const _brandBlue = _ServiceRequestsScreenState._brandBlue;
  static const _brandAccent = _ServiceRequestsScreenState._brandAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brandBlue],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x330A4FA8), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _brandAccent.withValues(alpha: 0.14)),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'My Service Requests',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              count == 0
                                  ? 'Track your requests here'
                                  : '$count active request${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
