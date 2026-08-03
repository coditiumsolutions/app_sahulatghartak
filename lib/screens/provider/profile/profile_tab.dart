import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../providers/provider_document_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/provider_availability_helper.dart';
import '../../../utils/provider_routes.dart';
import '../../../widgets/curved_profile_header.dart';
import '../../../widgets/provider/provider_tab_header.dart' show providerBrandDark, providerBrandBlue, providerBrandAccent;
import '../../home_screen.dart';
import '../../landing_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const double _avatarRadius = 46;
  static const double _headerHeight = 150;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      final dashboard = context.read<ProviderDashboardProvider>();
      dashboard.loadProviderDetail(providerUid);
      dashboard.loadAvailabilityStatus(providerUid);
      context.read<ProviderDocumentProvider>().loadDocuments(providerUid);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final dashboard = context.watch<ProviderDashboardProvider>();
    final detail = dashboard.providerDetail;
    final profilePhotoUrl = context.watch<ProviderDocumentProvider>().profilePhotoUrl;

    if (dashboard.profileLoading && detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (dashboard.profileError != null && detail == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load profile: ${dashboard.profileError}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (detail == null) {
      return const Scaffold(body: Center(child: Text('No profile data found.')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: CurvedProfileHeader(
        color: providerBrandBlue,
        headerColors: const [providerBrandDark, providerBrandBlue],
        headerHeight: _headerHeight,
        avatarRadius: _avatarRadius,
        onRefresh: () async => _loadProfile(),
        avatar: CircleAvatar(
          backgroundColor: providerBrandBlue,
          backgroundImage: profilePhotoUrl != null ? NetworkImage(profilePhotoUrl) : null,
          child: profilePhotoUrl == null ? const Icon(Icons.person, color: Colors.white, size: 42) : null,
        ),
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
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF14213D), letterSpacing: -0.2),
                  ),
                ),
                if (detail.isVerified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: providerBrandBlue, size: 20)),
              ],
            ),
            const SizedBox(height: 4),
            Text(detail.categoryName, style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${detail.averageRating.toStringAsFixed(1)} (${detail.totalReviews} reviews)', style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
              ],
            ),
            if (currentUser != null) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.verified_user_rounded,
                      label: 'ACCOUNT TYPE',
                      value: currentUser.role,
                      color: providerBrandBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.tag_rounded,
                      label: 'USER ID',
                      value: '${currentUser.userId}',
                      color: providerBrandAccent,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const _SectionHeader('Provider Details'),
            _InfoCard(
              children: [
                ListTile(leading: const Icon(Icons.badge_rounded, color: providerBrandBlue), title: const Text('Provider ID'), subtitle: Text('${detail.uid}')),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.phone_rounded, color: providerBrandBlue), title: const Text('Mobile Number'), subtitle: Text(detail.mobileNo)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.credit_card_rounded, color: providerBrandBlue), title: const Text('CNIC'), subtitle: Text(detail.cnic)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.wc_rounded, color: providerBrandBlue), title: const Text('Gender'), subtitle: Text(detail.gender)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.work_history_rounded, color: providerBrandBlue), title: const Text('Experience'), subtitle: Text('${detail.experienceYears} years')),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.category_rounded, color: providerBrandBlue), title: const Text('Category'), subtitle: Text('${detail.categoryName} (ID: ${detail.categoryId})')),
                if (detail.description.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.description_rounded, color: providerBrandBlue), title: const Text('Description'), subtitle: Text(detail.description)),
                ],
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.task_alt_rounded, color: providerBrandBlue), title: const Text('Jobs Completed'), subtitle: Text('${detail.totalJobsCompleted}')),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user_rounded, color: providerBrandBlue),
                  title: const Text('Verification Status'),
                  subtitle: Text(detail.isVerified ? 'Verified' : 'Pending Verification'),
                ),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.event_rounded, color: providerBrandBlue), title: const Text('Member Since'), subtitle: Text(DateFormat('dd MMM yyyy').format(detail.createdOn))),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Availability'),
            _InfoCard(
              children: [
                ListTile(
                  leading: Icon(dashboard.isOnline ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded, color: dashboard.isOnline ? Colors.green : Colors.grey),
                  title: const Text('Status'),
                  subtitle: Text(dashboard.isOnline ? 'Online — receiving new requests' : 'Offline'),
                  trailing: dashboard.availabilityLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Switch(
                          value: dashboard.isOnline,
                          activeThumbColor: Colors.green,
                          onChanged: (v) => toggleProviderOnlineStatus(context, v),
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded, color: providerBrandBlue),
                  title: const Text('Available Timing'),
                  subtitle: Text(dashboard.availableTiming ?? detail.availableTiming ?? 'Not set'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: kProminentFilledButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profile'),
                onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.editProfile),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('My Documents'),
                onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.verificationDocuments),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Customers Dashboard'),
                onPressed: () => Navigator.of(context).pushNamed(HomeScreen.routeName),
              ),
            ),
          ],
        ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: providerBrandBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF14213D), letterSpacing: -0.1)),
          ],
        ),
      ),
    );
  }
}

/// White, shadowed container used for grouped [ListTile] rows, matching the
/// customer profile screen's card style (see `screens/profile_screen.dart`).
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: providerBrandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
