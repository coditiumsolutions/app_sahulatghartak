import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/provider_routes.dart';
import '../../../widgets/curved_profile_header.dart';
import '../../home_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const double _avatarRadius = 46;
  static const double _headerHeight = 75;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      context.read<ProviderDashboardProvider>().loadProviderDetail(providerUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final dashboard = context.watch<ProviderDashboardProvider>();
    final detail = dashboard.providerDetail;

    if (dashboard.profileLoading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboard.profileError != null && detail == null) {
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

    if (detail == null) {
      return const Center(child: Text('No profile data found.'));
    }

    return CurvedProfileHeader(
      color: kPrimaryColor,
      headerHeight: _headerHeight,
      avatarRadius: _avatarRadius,
      onRefresh: () async => _loadProfile(),
      avatar: const CircleAvatar(backgroundColor: kPrimaryColor, child: Icon(Icons.person, color: Colors.white, size: 42)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, _avatarRadius + 20, 20, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    detail.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                if (detail.isVerified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified, color: Colors.blue, size: 20)),
              ],
            ),
            const SizedBox(height: 4),
            Text(detail.categoryName, style: TextStyle(color: Colors.black.withOpacity(0.5))),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${detail.averageRating.toStringAsFixed(1)} (${detail.totalReviews} reviews)'),
              ],
            ),
            if (currentUser != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.account_circle,
                      label: 'ACCOUNT TYPE',
                      value: currentUser.role,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.tag,
                      label: 'USER ID',
                      value: '${currentUser.userId}',
                      color: kSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const _SectionHeader('Provider Details'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.badge, color: kPrimaryColor), title: const Text('Provider ID'), subtitle: Text('${detail.uid}')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.phone, color: kPrimaryColor), title: const Text('Mobile Number'), subtitle: Text(detail.mobileNo)),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.credit_card, color: kPrimaryColor), title: const Text('CNIC'), subtitle: Text(detail.cnic)),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.wc, color: kPrimaryColor), title: const Text('Gender'), subtitle: Text(detail.gender)),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.work_history, color: kPrimaryColor), title: const Text('Experience'), subtitle: Text('${detail.experienceYears} years')),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.category, color: kPrimaryColor), title: const Text('Category'), subtitle: Text('${detail.categoryName} (ID: ${detail.categoryId})')),
                  if (detail.description.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.description, color: kPrimaryColor), title: const Text('Description'), subtitle: Text(detail.description)),
                  ],
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.task_alt, color: kPrimaryColor), title: const Text('Jobs Completed'), subtitle: Text('${detail.totalJobsCompleted}')),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_user, color: kPrimaryColor),
                    title: const Text('Verification Status'),
                    subtitle: Text(detail.isVerified ? 'Verified' : 'Pending Verification'),
                  ),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.event, color: kPrimaryColor), title: const Text('Member Since'), subtitle: Text(DateFormat('dd MMM yyyy').format(detail.createdOn))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Availability'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(detail.isAvailable ? Icons.wifi_tethering : Icons.wifi_tethering_off, color: detail.isAvailable ? Colors.green : Colors.grey),
                    title: const Text('Status'),
                    subtitle: Text(detail.isAvailable ? 'Online' : 'Offline'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: kPrimaryColor),
                    title: const Text('Available Timing'),
                    subtitle: Text(detail.availableTiming ?? 'Not set'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: kProminentFilledButtonStyle(kPrimaryColor),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.editProfile),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(kPrimaryColor),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('My Documents'),
                onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.verificationDocuments),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(kPrimaryColor),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Customers Dashboard'),
                onPressed: () => Navigator.of(context).pushNamed(HomeScreen.routeName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor)),
      ),
    );
  }
}
