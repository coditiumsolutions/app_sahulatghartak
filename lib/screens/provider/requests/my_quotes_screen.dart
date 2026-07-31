import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/quote.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/status_chip.dart';

class MyQuotesScreen extends StatelessWidget {
  static const routeName = '/provider/quotes';
  const MyQuotesScreen({super.key});

  Color _statusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.pending:
        return Colors.orange;
      case QuoteStatus.accepted:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
    }
  }

  String _statusLabel(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.pending:
        return 'Pending';
      case QuoteStatus.accepted:
        return 'Accepted';
      case QuoteStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = context.watch<ProviderDashboardProvider>().quotes;

    return Scaffold(
      appBar: AppBar(title: const Text('My Quotes'), backgroundColor: kPrimaryColor),
      body: quotes.isEmpty
          ? const Center(child: Text('No quotes submitted yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: quotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final quote = quotes[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(quote.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Rs ${quote.amount.toStringAsFixed(0)} • ETA: ${quote.eta}'),
                    trailing: StatusChip(label: _statusLabel(quote.status), color: _statusColor(quote.status)),
                  ),
                );
              },
            ),
    );
  }
}
