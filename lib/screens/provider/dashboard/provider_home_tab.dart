import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/provider_availability_helper.dart';
import '../../../widgets/provider/dashboard_stat_card.dart';

class ProviderHomeTab extends StatelessWidget {
  const ProviderHomeTab({Key? key}) : super(key: key);

  Future<void> _refresh(BuildContext context) async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;
    final dashboard = context.read<ProviderDashboardProvider>();
    await Future.wait([
      dashboard.loadIncomingRequests(providerUid),
      dashboard.loadAvailabilityStatus(providerUid),
      dashboard.loadProviderDetail(providerUid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final username = context.watch<AuthProvider>().currentUser?.username ?? '';
    final firstName = username.trim().isEmpty ? null : username.trim().split(' ').first;

    final cards = [
      DashboardStatCard(label: 'Available Requests', value: '${dashboard.incomingRequests.length}', icon: Icons.inbox, color: kPrimaryColor),
      DashboardStatCard(label: 'Active Jobs', value: '${dashboard.activeJobs.length}', icon: Icons.work, color: kAccentColor),
      DashboardStatCard(label: 'Completed Today', value: '${dashboard.completedJobsToday}', icon: Icons.task_alt, color: Colors.green),
      DashboardStatCard(label: "Today's Earnings", value: 'Rs ${dashboard.earningsSummary.today.toStringAsFixed(0)}', icon: Icons.attach_money, color: Colors.orange),
      DashboardStatCard(label: 'Average Rating', value: dashboard.averageRating.toStringAsFixed(1), icon: Icons.star, color: Colors.amber),
      DashboardStatCard(label: 'Wallet Balance', value: 'Rs ${dashboard.walletBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet, color: kSecondaryColor),
    ];

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Text(
                      (firstName ?? 'P')[0].toUpperCase(),
                      style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName == null ? 'Welcome back!' : 'Welcome back, $firstName!',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dashboard.isOnline ? "You're online and visible to customers" : "You're offline right now",
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => toggleProviderOnlineStatus(context, !dashboard.isOnline),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: dashboard.isOnline ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(dashboard.isOnline ? Icons.wifi_tethering : Icons.wifi_tethering_off, color: Colors.white, size: 16),
                          const SizedBox(height: 2),
                          Text(
                            dashboard.isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
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
