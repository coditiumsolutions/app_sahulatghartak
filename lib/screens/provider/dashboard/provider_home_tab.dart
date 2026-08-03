import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/provider_availability_helper.dart';
import '../../../widgets/provider/dashboard_stat_card.dart';
import '../../../widgets/provider/provider_tab_header.dart';

class ProviderHomeTab extends StatelessWidget {
  const ProviderHomeTab({super.key});

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
      DashboardStatCard(label: 'Active Bookings', value: '${dashboard.activeJobs.length}', icon: Icons.work, color: kAccentColor),
      DashboardStatCard(label: 'Completed Today', value: '${dashboard.completedJobsToday}', icon: Icons.task_alt, color: Colors.green),
      DashboardStatCard(label: "Today's Earnings", value: 'Rs ${dashboard.earningsSummary.today.toStringAsFixed(0)}', icon: Icons.attach_money, color: Colors.orange),
      DashboardStatCard(label: 'Average Rating', value: dashboard.averageRating.toStringAsFixed(1), icon: Icons.star, color: Colors.amber),
      DashboardStatCard(label: 'Wallet Balance', value: 'Rs ${dashboard.walletBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet, color: kSecondaryColor),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: firstName == null ? 'Welcome back!' : 'Welcome back, $firstName!',
        subtitle: dashboard.isOnline ? "You're online and visible to customers" : "You're offline right now",
        trailing: GestureDetector(
          onTap: () => toggleProviderOnlineStatus(context, !dashboard.isOnline),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: dashboard.isOnline ? Colors.green.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.15),
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
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(color: providerBrandBlue, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF14213D), letterSpacing: -0.2),
                  ),
                ],
              ),
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
      ),
    );
  }
}
