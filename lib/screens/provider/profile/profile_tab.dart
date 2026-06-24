import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/provider_routes.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId != null) {
      context.read<ProviderDashboardProvider>().loadProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final profile = dashboard.profile;

    if (dashboard.profileLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboard.profileError != null && profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load profile: ${dashboard.profileError}'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (profile == null) {
      return const Center(child: Text('No profile data found.'));
    }

    return RefreshIndicator(
      onRefresh: () async => _loadProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 48, backgroundColor: kPrimaryColor, child: Icon(Icons.person, color: Colors.white, size: 48)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(profile.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (profile.isVerified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified, color: Colors.blue, size: 20)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(profile.rating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.badge, color: kPrimaryColor), title: const Text('CNIC'), subtitle: Text(profile.cnic)),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.work_history, color: kPrimaryColor), title: const Text('Experience'), subtitle: Text('${profile.experienceYears} years')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.category, color: kPrimaryColor), title: const Text('Category ID'), subtitle: Text('${profile.categoryUid}')),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_user, color: kPrimaryColor),
                    title: const Text('Verification Status'),
                    subtitle: Text(profile.isVerified ? 'Verified' : 'Pending Verification'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.editProfile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
