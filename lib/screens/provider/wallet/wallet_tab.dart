import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/provider_wallet.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_wallet_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/provider/tab_state_placeholder.dart';

String _humanizeReason(String reason) {
  switch (reason) {
    case 'JobEarning':
      return 'Job Earning';
    case 'CashCollect':
      return 'Cash Collected';
    case 'Payout':
      return 'Payout';
    default:
      // Fallback: split PascalCase into words for any reason not explicitly mapped.
      return reason.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (m) => ' ').trim();
  }
}

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWallet());
  }

  void _loadWallet() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      context.read<ProviderWalletProvider>().loadWallet(providerUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderWalletProvider>();
    final wallet = provider.wallet;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: const ProviderTabHeader(title: 'Wallet', subtitle: 'Balance and payment history'),
      body: provider.loading && wallet == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && wallet == null
              ? RefreshIndicator(
                  onRefresh: () async => _loadWallet(),
                  child: TabStatePlaceholder(
                    icon: Icons.wifi_off_rounded,
                    color: Colors.red,
                    title: "Couldn't load wallet",
                    message: provider.error,
                    onRetry: _loadWallet,
                  ),
                )
              : wallet == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: () async => _loadWallet(),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BalanceCard(wallet: wallet),
                                  const SizedBox(height: 16),
                                  Text('Transaction History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  if (wallet.transactions.isEmpty) const _EmptyTransactions(),
                                ],
                              ),
                            ),
                          ),
                          if (wallet.transactions.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              sliver: SliverList.builder(
                                itemCount: wallet.transactions.length,
                                itemBuilder: (context, index) => _TransactionTile(transaction: wallet.transactions[index]),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, size: 30, color: kPrimaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2233)),
          ),
          const SizedBox(height: 6),
          Text(
            'Your earnings and payouts will show up here once you complete a job.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final ProviderWallet wallet;

  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final isOwed = wallet.balance >= 0;
    final balanceColor = isOwed ? Colors.green.shade700 : Colors.amber.shade800;
    final balanceLabel = isOwed ? 'Company owes you' : 'You owe the company';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: balanceColor.withValues(alpha: 0.15),
                radius: 22,
                child: Icon(isOwed ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: balanceColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(balanceLabel, style: TextStyle(color: Colors.grey[600], fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs ${wallet.balance.abs().toStringAsFixed(0)}',
                      style: TextStyle(color: balanceColor, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Colors.grey[500], size: 18),
              const SizedBox(width: 8),
              Text('Pending Payout', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Rs ${wallet.pendingPayoutTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: kPrimaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionEntry transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.signedAmount >= 0;
    final amountColor = isCredit ? Colors.green.shade700 : Colors.red.shade700;
    final sign = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: amountColor.withValues(alpha: 0.12),
            radius: 18,
            child: Icon(isCredit ? Icons.add_rounded : Icons.remove_rounded, color: amountColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_humanizeReason(transaction.reason), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(transaction.createdOn),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11.5),
                ),
                if (transaction.bookingUid != null) ...[
                  const SizedBox(height: 2),
                  Text('Booking #${transaction.bookingUid}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ],
            ),
          ),
          Text(
            '$sign Rs ${transaction.signedAmount.abs().toStringAsFixed(0)}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
