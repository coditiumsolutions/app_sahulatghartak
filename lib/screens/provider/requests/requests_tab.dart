import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/service_request.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/provider/tab_state_placeholder.dart';

Color _requestStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return kAccentColor;
    case 'quoted':
      return Colors.orange;
    case 'rejected':
      return Colors.red;
    default:
      return kPrimaryColor;
  }
}

IconData _requestStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'accepted':
      return Icons.check_circle_rounded;
    case 'quoted':
      return Icons.request_quote_rounded;
    case 'rejected':
      return Icons.cancel_rounded;
    default:
      return Icons.hourglass_top_rounded;
  }
}

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  void _loadRequests() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      context.read<ProviderDashboardProvider>().loadIncomingRequests(providerUid);
    }
  }

  void _viewDetails(BuildContext context, ServiceRequest request) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(request.requestTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${request.customerName}'),
            Text('Mobile: ${request.customerMobile}'),
            Text('Category: ${request.categoryName}'),
            Text('Description: ${request.description}'),
            Text('Address: ${request.serviceAddress}'),
            Text('Status: ${request.status}'),
            Text('Requested: ${DateFormat('dd MMM yyyy, hh:mm a').format(request.requestDate)}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _sendQuote(BuildContext context, ServiceRequest request) {
    final amountController = TextEditingController();
    final etaController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quote Amount (Rs)')),
            const SizedBox(height: 12),
            TextField(controller: etaController, decoration: const InputDecoration(labelText: 'ETA (e.g. 30 mins)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              final eta = etaController.text.trim().isEmpty ? 'N/A' : etaController.text.trim();
              if (amount > 0) {
                context.read<ProviderDashboardProvider>().sendQuote(request, amount, eta);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote sent successfully')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest(BuildContext context, ServiceRequest request) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reject Request',
      message: 'Are you sure you want to reject "${request.requestTitle}"? This cannot be undone.',
      confirmLabel: 'Reject',
      icon: Icons.cancel_outlined,
      color: Colors.red,
    );
    if (confirmed != true || !context.mounted) return;
    context.read<ProviderDashboardProvider>().rejectRequest(request.id);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final requests = dashboard.incomingRequests;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Incoming Requests',
        subtitle: requests.isEmpty ? 'No requests right now' : '${requests.length} request${requests.length == 1 ? '' : 's'} waiting',
      ),
      body: dashboard.requestsLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboard.requestsError != null
              ? RefreshIndicator(
                  onRefresh: () async => _loadRequests(),
                  child: TabStatePlaceholder(
                    icon: Icons.wifi_off_rounded,
                    color: Colors.red,
                    title: 'Couldn\'t load requests',
                    message: dashboard.requestsError,
                    onRetry: _loadRequests,
                  ),
                )
              : requests.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () async => _loadRequests(),
                      child: const TabStatePlaceholder(
                        icon: Icons.inbox_rounded,
                        color: kPrimaryColor,
                        title: 'No requests yet',
                        message: 'New service requests from customers will show up here as soon as they come in.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadRequests(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return _IncomingRequestCard(
                            request: request,
                            onViewDetails: () => _viewDetails(context, request),
                            onSendQuote: () => _sendQuote(context, request),
                            onReject: () => _rejectRequest(context, request),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// Incoming-request card matching the customer side's white-card/left-rail
/// style ([lib/screens/service_requests_screen.dart]'s `_RequestCard`).
class _IncomingRequestCard extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback onViewDetails;
  final VoidCallback onSendQuote;
  final VoidCallback onReject;

  const _IncomingRequestCard({
    required this.request,
    required this.onViewDetails,
    required this.onSendQuote,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _requestStatusColor(request.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            request.customerName.isNotEmpty ? request.customerName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(request.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A2233))),
                              const SizedBox(height: 2),
                              Text(request.categoryName, style: TextStyle(color: Colors.grey[500], fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_requestStatusIcon(request.status), size: 13, color: statusColor),
                              const SizedBox(width: 4),
                              Text(request.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(request.requestTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF1A2233))),
                    if (request.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        request.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF6F8FC), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: kPrimaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  request.serviceAddress,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF3A4658), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.call_rounded, size: 16, color: kPrimaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  request.customerMobile,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF3A4658), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Requested ${DateFormat('dd MMM yyyy, hh:mm a').format(request.requestDate)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: onViewDetails,
                            child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: onSendQuote,
                            child: const Text('Send Quote', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.red.withValues(alpha: 0.08),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                            tooltip: 'Reject',
                            onPressed: onReject,
                          ),
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
    );
  }
}
