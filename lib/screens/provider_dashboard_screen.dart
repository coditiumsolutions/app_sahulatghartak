import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/provider_dashboard_provider.dart';
import '../utils/constants.dart';
import '../utils/provider_routes.dart';
import '../widgets/provider/provider_app_drawer.dart';
import 'provider/dashboard/provider_home_tab.dart';
import 'provider/earnings/earnings_tab.dart';
import 'provider/jobs/jobs_tab.dart';
import 'provider/profile/profile_tab.dart';
import 'provider/requests/requests_tab.dart';

class ProviderDashboardScreen extends StatefulWidget {
  static const routeName = ProviderRoutes.dashboard;
  const ProviderDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Requests', 'Active Jobs', 'Earnings', 'Profile'];

  static const _tabs = [
    ProviderHomeTab(),
    RequestsTab(),
    JobsTab(),
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
      appBar: AppBar(title: Text(_titles[_index]), backgroundColor: kPrimaryColor),
      drawer: const ProviderAppDrawer(),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: kPrimaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
