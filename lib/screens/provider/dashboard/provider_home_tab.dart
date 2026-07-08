import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/provider_availability_helper.dart';
import '../../../widgets/provider/dashboard_stat_card.dart';

class ProviderHomeTab extends StatelessWidget {
  const ProviderHomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();

    final cards = [
      DashboardStatCard(label: 'Available Requests', value: '${dashboard.incomingRequests.length}', icon: Icons.inbox, color: kPrimaryColor),
      DashboardStatCard(label: 'Active Jobs', value: '${dashboard.activeJobs.length}', icon: Icons.work, color: kAccentColor),
      DashboardStatCard(label: 'Completed Today', value: '${dashboard.completedJobsToday}', icon: Icons.task_alt, color: Colors.green),
      DashboardStatCard(label: "Today's Earnings", value: 'Rs ${dashboard.earningsSummary.today.toStringAsFixed(0)}', icon: Icons.attach_money, color: Colors.orange),
      DashboardStatCard(label: 'Average Rating', value: dashboard.averageRating.toStringAsFixed(1), icon: Icons.star, color: Colors.amber),
      DashboardStatCard(label: 'Wallet Balance', value: 'Rs ${dashboard.walletBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet, color: kSecondaryColor),
    ];

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Welcome back!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(dashboard.isOnline ? 'Online' : 'Offline', style: TextStyle(color: dashboard.isOnline ? Colors.green : Colors.grey, fontWeight: FontWeight.w600)),
                    Switch(
                      value: dashboard.isOnline,
                      activeColor: Colors.green,
                      onChanged: (v) => toggleProviderOnlineStatus(context, v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: cards,
            ),
          ],
        ),
      ),
    );
  }
}
