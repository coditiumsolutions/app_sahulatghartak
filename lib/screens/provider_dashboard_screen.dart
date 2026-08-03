import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/provider_dashboard_provider.dart';
import '../utils/provider_routes.dart';
import '../widgets/provider/provider_bottom_nav.dart';
import 'provider/dashboard/provider_home_tab.dart';
import 'provider/earnings/earnings_tab.dart';
import 'provider/jobs/jobs_tab.dart';
import 'provider/profile/profile_tab.dart';
import 'provider/requests/requests_tab.dart';

class ProviderDashboardScreen extends StatefulWidget {
  static const routeName = ProviderRoutes.dashboard;
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _index = 0;

  static const _tabs = [
    ProviderHomeTab(),
    RequestsTab(),
    BookingsTab(),
    EarningsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser == null) return;
      final dashboard = context.read<ProviderDashboardProvider>();
      if (currentUser.providerUid != null) {
        dashboard.loadProviderDetail(currentUser.providerUid!);
        dashboard.loadIncomingRequests(currentUser.providerUid!);
        dashboard.loadAvailabilityStatus(currentUser.providerUid!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: ProviderBottomNavigation(
        currentIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
