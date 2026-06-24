import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/support_ticket.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/status_chip.dart';

class SupportCenterScreen extends StatelessWidget {
  static const routeName = '/provider/support';
  const SupportCenterScreen({Key? key}) : super(key: key);

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.orange;
      case TicketStatus.inProgress:
        return kAccentColor;
      case TicketStatus.resolved:
        return Colors.green;
    }
  }

  Future<void> _createTicket(BuildContext context) async {
    TicketCategory category = TicketCategory.paymentIssue;
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Create Support Ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TicketCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: TicketCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (subjectController.text.trim().isEmpty) return;
                context.read<ProviderDashboardProvider>().createSupportTicket(
                      category: category,
                      subject: subjectController.text.trim(),
                      description: descriptionController.text.trim(),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tickets = context.watch<ProviderDashboardProvider>().supportTickets;

    return Scaffold(
      appBar: AppBar(title: const Text('Support Center'), backgroundColor: kPrimaryColor),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTicket(context),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.phone_in_talk, color: kPrimaryColor),
              title: const Text('Contact Support'),
              subtitle: const Text('Call 0800-12345 or email support@sahulatghartak.com'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Your Tickets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (tickets.isEmpty) const Text('No support tickets yet.'),
          ...tickets.map((ticket) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.bold))),
                          StatusChip(label: ticket.status.label, color: _statusColor(ticket.status)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(ticket.category.label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(ticket.description),
                      const SizedBox(height: 6),
                      Text(DateFormat('dd MMM yyyy').format(ticket.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
