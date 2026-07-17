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
  const ServiceRequestsScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final requestState = context.watch<CustomerServiceRequestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Service Requests'), backgroundColor: kPrimaryColor),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
      body: RefreshIndicator(
        onRefresh: () async => _loadRequests(),
        child: requestState.loading
            ? const Center(child: CircularProgressIndicator())
            : requestState.error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [Padding(padding: const EdgeInsets.all(24), child: Text(requestState.error!, style: const TextStyle(color: Colors.red)))],
                  )
                : requestState.requests.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No service requests yet.')))],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: requestState.requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = requestState.requests[index];
                          final deleting = requestState.deletingUid == request.uid;
                          final cancelling = requestState.cancellingUid == request.uid;

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(request.serviceTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: _statusColor(request.status).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
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
