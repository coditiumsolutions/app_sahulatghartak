import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/provider_dashboard_provider.dart';
import '../../utils/constants.dart';
import '../../utils/provider_routes.dart';

class ProviderAppDrawer extends StatelessWidget {
  const ProviderAppDrawer({super.key});

  void _goTo(BuildContext context, String routeName) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProviderDashboardProvider>().providerDetail;
    final username = context.watch<AuthProvider>().currentUser?.username ?? '';

    final items = <_DrawerItem>[
      _DrawerItem(Icons.dashboard, 'Dashboard', () => Navigator.of(context).pop()),
      _DrawerItem(Icons.toggle_on, 'Online / Offline Status', () => _goTo(context, ProviderRoutes.onlineStatus)),
      _DrawerItem(Icons.inbox, 'Incoming Requests', () => Navigator.of(context).pop()),
      _DrawerItem(Icons.request_quote, 'My Quotes', () => _goTo(context, ProviderRoutes.myQuotes)),
      _DrawerItem(Icons.work, 'Active Bookings', () => Navigator.of(context).pop()),
      _DrawerItem(Icons.history, 'Job History', () => _goTo(context, ProviderRoutes.jobHistory)),
      _DrawerItem(Icons.attach_money, 'Earnings', () => Navigator.of(context).pop()),
      _DrawerItem(Icons.account_balance_wallet, 'Wallet', () => _goTo(context, ProviderRoutes.wallet)),
      _DrawerItem(Icons.star, 'Reviews & Ratings', () => _goTo(context, ProviderRoutes.reviews)),
      _DrawerItem(Icons.notifications, 'Notifications', () => _goTo(context, ProviderRoutes.notifications)),
      _DrawerItem(Icons.chat, 'Chat', () => _goTo(context, ProviderRoutes.chatList)),
      _DrawerItem(Icons.calendar_today, 'Availability Schedule', () => _goTo(context, ProviderRoutes.schedule)),
      _DrawerItem(Icons.handyman, 'Services Offered', () => _goTo(context, ProviderRoutes.servicesOffered)),
      _DrawerItem(Icons.description, 'Documents', () => _goTo(context, ProviderRoutes.documents)),
      _DrawerItem(Icons.support_agent, 'Support Center', () => _goTo(context, ProviderRoutes.support)),
      _DrawerItem(Icons.settings, 'Settings', () => _goTo(context, ProviderRoutes.settings)),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: kPrimaryColor),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.engineering, color: kPrimaryColor, size: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(profile?.fullName ?? username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(username, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((item) => ListTile(leading: Icon(item.icon, color: kPrimaryColor), title: Text(item.label), onTap: item.onTap)),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _DrawerItem(this.icon, this.label, this.onTap);
}
