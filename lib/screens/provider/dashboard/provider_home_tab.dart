import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_bookings_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../providers/provider_wallet_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/provider_availability_helper.dart';
import '../../../utils/provider_routes.dart';
import '../../../widgets/provider/dashboard_stat_card.dart';
import '../../../widgets/provider/notifications_entry_card.dart';
import '../../../widgets/provider/provider_tab_header.dart';

const _kRequestsTabIndex = 1;
const _kBookingsTabIndex = 2;
const _kWalletTabIndex = 3;

class ProviderHomeTab extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const ProviderHomeTab({super.key, this.onNavigateToTab});

  @override
  State<ProviderHomeTab> createState() => _ProviderHomeTabState();
}

class _ProviderHomeTabState extends State<ProviderHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;
    final dashboard = context.read<ProviderDashboardProvider>();
    await Future.wait([
      dashboard.loadAvailabilityStatus(providerUid),
      dashboard.loadProviderDetail(providerUid),
      context.read<ProviderBookingsProvider>().loadBookings(providerUid),
      context.read<ProviderWalletProvider>().loadWallet(providerUid),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final bookingsProvider = context.watch<ProviderBookingsProvider>();
    final walletProvider = context.watch<ProviderWalletProvider>();
    final username = context.watch<AuthProvider>().currentUser?.username ?? '';
    final firstName = username.trim().isEmpty ? null : username.trim().split(' ').first;

    final pendingRequests = bookingsProvider.bookings.where((b) => b.status == 'Pending').length;
    final activeBookings = bookingsProvider.bookings
        .where((b) => b.status == 'Accepted' || b.status == 'In Progress')
        .length;
    final now = DateTime.now();
    final completedToday = bookingsProvider.bookings
        .where((b) => b.completedOn != null && b.completedOn!.year == now.year && b.completedOn!.month == now.month && b.completedOn!.day == now.day)
        .length;
    final averageRating = dashboard.providerDetail?.averageRating ?? 0;
    final walletBalance = walletProvider.wallet?.balance;

    final cards = [
      DashboardStatCard(
        label: 'Available Requests',
        value: '$pendingRequests',
        icon: Icons.inbox,
        color: kPrimaryColor,
        onTap: () => widget.onNavigateToTab?.call(_kRequestsTabIndex),
      ),
      DashboardStatCard(
        label: 'Active Bookings',
        value: '$activeBookings',
        icon: Icons.work,
        color: kAccentColor,
        onTap: () => widget.onNavigateToTab?.call(_kBookingsTabIndex),
      ),
      DashboardStatCard(label: 'Completed Today', value: '$completedToday', icon: Icons.task_alt, color: Colors.green),
      DashboardStatCard(label: 'Average Rating', value: averageRating.toStringAsFixed(1), icon: Icons.star, color: Colors.amber),
      DashboardStatCard(
        label: 'Wallet Balance',
        value: walletBalance == null ? '—' : 'Rs ${walletBalance.toStringAsFixed(0)}',
        icon: Icons.account_balance_wallet,
        color: kSecondaryColor,
        onTap: () => widget.onNavigateToTab?.call(_kWalletTabIndex),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: firstName == null ? 'Welcome back!' : 'Welcome back, $firstName!',
        subtitle: dashboard.isOnline ? "You're online and visible to customers" : "You're offline right now",
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Image.asset('assets/icon/app_logo_transparent.png', fit: BoxFit.contain),
        ),
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
        onRefresh: _refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationsEntryCard(
                onTap: () => Navigator.of(context).pushNamed(ProviderRoutes.notifications),
              ),
              const SizedBox(height: 16),
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
