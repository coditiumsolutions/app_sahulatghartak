import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/service_request.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({Key? key}) : super(key: key);

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
    final providerId = context.read<AuthProvider>().currentUser?.userId;
    if (providerId != null) {
      context.read<ProviderDashboardProvider>().loadIncomingRequests(providerId);
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

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final requests = dashboard.incomingRequests;

    if (dashboard.requestsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboard.requestsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load requests: ${dashboard.requestsError}'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadRequests, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadRequests(),
        child: ListView(children: const [SizedBox(height: 200), Center(child: Text('No incoming requests right now.'))]),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: kPrimaryColor, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(request.categoryName, style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text(request.status, style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(request.requestTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(request.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(child: Text(request.serviceAddress, style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _viewDetails(context, request), child: const Text('View Details'))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(onPressed: () => _sendQuote(context, request), child: const Text('Send Quote'))),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => dashboard.rejectRequest(request.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
