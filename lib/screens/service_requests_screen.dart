import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer_service_request.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_service_request_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text('Are you sure you want to delete "${request.serviceTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final requestProvider = context.read<CustomerServiceRequestProvider>();
    final success = await requestProvider.deleteRequest(request.uid);
    if (!mounted) return;

    final message = success ? 'Request deleted' : (requestProvider.error ?? 'Failed to delete request');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancelRequest(CustomerServiceRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Text('Are you sure you want to cancel "${request.serviceTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final requestProvider = context.read<CustomerServiceRequestProvider>();
    final success = await requestProvider.cancelRequest(request);
    if (!mounted) return;

    final message = success ? 'Request cancelled' : (requestProvider.error ?? 'Failed to cancel request');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      bottomNavigationBar: widget.embedded ? null : const AppBottomNavigation(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: () async => _loadRequests(),
        child: requestState.loading
            ? const Center(child: CircularProgressIndicator())
            : requestState.error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(padding: const EdgeInsets.all(24), child: Text(requestState.error!, style: const TextStyle(color: Colors.red))),
                    ],
                  )
                : requestState.requests.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No service requests yet.'))),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: requestState.requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = requestState.requests[index];
                          final deleting = requestState.deletingUid == request.uid;
                          final cancelling = requestState.cancellingUid == request.uid;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: _brandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(request.serviceTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: _statusColor(request.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                        child: Text(request.status, style: TextStyle(color: _statusColor(request.status), fontWeight: FontWeight.w600, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(request.categoryName, style: TextStyle(color: Colors.grey[600])),
                                  const SizedBox(height: 8),
                                  Text(request.serviceDescription),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.location_on, size: 16, color: kPrimaryColor),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(request.addressTitle, overflow: TextOverflow.ellipsis)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.event, size: 16, color: kPrimaryColor),
                                    const SizedBox(width: 4),
                                    Text('${request.preferredServiceDate} at ${request.preferredServiceTime}'),
                                    if (request.isUrgent) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.priority_high, size: 16, color: Colors.red),
                                      const Text('Urgent', style: TextStyle(color: Colors.red, fontSize: 12)),
                                    ],
                                  ]),
                                  if (request.estimatedBudget > 0) ...[
                                    const SizedBox(height: 4),
                                    Text('Estimated Budget: Rs. ${request.estimatedBudget.toStringAsFixed(0)}'),
                                  ],
                                  const SizedBox(height: 4),
                                  Text('Requested on ${DateFormat('dd MMM yyyy').format(request.createdOn)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  if (_canCancel(request.status) || _canDelete(request.status)) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (_canCancel(request.status))
                                          cancelling
                                              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                              : TextButton.icon(
                                                  onPressed: () => _cancelRequest(request),
                                                  icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
                                                  label: const Text('Cancel Request', style: TextStyle(color: Colors.orange)),
                                                ),
                                        if (_canDelete(request.status))
                                          deleting
                                              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                              : TextButton.icon(
                                                  onPressed: () => _deleteRequest(request),
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
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
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x330A4FA8), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _brandAccent.withValues(alpha: 0.14)),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Service Requests',
                            style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            count == 0 ? 'Track your requests here' : '$count active request${count == 1 ? '' : 's'}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
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
