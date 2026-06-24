import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/wallet_transaction.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class WalletScreen extends StatelessWidget {
  static const routeName = '/provider/wallet';
  const WalletScreen({Key? key}) : super(key: key);

  void _requestWithdrawal(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Withdrawal'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs)')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim()) ?? 0;
              final success = context.read<ProviderDashboardProvider>().requestWithdrawal(amount);
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Withdrawal request submitted' : 'Invalid or insufficient amount')));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final transactions = dashboard.walletTransactions;
    final withdrawals = transactions.where((t) => t.type == TransactionType.withdrawal).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet'), backgroundColor: kPrimaryColor),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: kPrimaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Balance', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Rs ${dashboard.walletBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimaryColor),
                      onPressed: () => _requestWithdrawal(context),
                      child: const Text('Request Withdrawal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(leading: Icon(Icons.account_balance, color: kPrimaryColor), title: Text('Bank Details'), subtitle: Text('HBL • Account ending in 4521')),
          ),
          const SizedBox(height: 20),
          Text('Withdrawal History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (withdrawals.isEmpty) const Text('No withdrawals yet.'),
          ...withdrawals.map((t) => ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                title: Text('Rs ${t.amount.toStringAsFixed(0)}'),
                subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(t.date)),
              )),
          const SizedBox(height: 20),
          Text('Transaction History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...transactions.map((t) => ListTile(
                leading: Icon(t.type == TransactionType.credit ? Icons.arrow_downward : Icons.arrow_upward, color: t.type == TransactionType.credit ? Colors.green : Colors.red),
                title: Text(t.description),
                subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(t.date)),
                trailing: Text(
                  '${t.type == TransactionType.credit ? '+' : '-'}Rs ${t.amount.toStringAsFixed(0)}',
                  style: TextStyle(color: t.type == TransactionType.credit ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                ),
              )),
        ],
      ),
    );
  }
}
