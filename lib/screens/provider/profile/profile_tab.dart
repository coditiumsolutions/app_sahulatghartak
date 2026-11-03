import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../providers/provider_document_provider.dart';
import '../../../providers/time_format_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/date_time_formatter.dart';
import '../../../utils/provider_availability_helper.dart';
import '../../../utils/privacy_policy_launcher.dart';
import '../../../utils/provider_routes.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/curved_profile_header.dart';
import '../../../widgets/delete_account_dialog.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/profile_kit.dart';
import '../../../widgets/provider/provider_tab_header.dart'
    show providerBrandDark, providerBrandBlue;
import '../../../widgets/provider/tab_state_placeholder.dart';
import '../../contact_us_screen.dart';
import '../../home_screen.dart';
import '../../landing_screen.dart';
import 'categories_and_titles_screen.dart';

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
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your account?',
      confirmLabel: 'Log Out',
      icon: Icons.logout_rounded,
      color: providerBrandBlue,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    context.read<TimeFormatProvider>().reset();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = await showDeleteAccountDialog(context);
    if (password == null || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.deleteAccount(password);
    if (!context.mounted) return;

    if (success) {
      await showMessageDialog(
        context,
        title: 'Account Deleted',
        message: 'Account deleted successfully.',
        type: MessageDialogType.success,
      );
      if (!context.mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
    } else {
      await showMessageDialog(
        context,
        title: 'Delete Failed',
        message: authProvider.error ?? 'Failed to delete account',
        type: MessageDialogType.error,
      );
    }
  }

  /// Skeleton of the final layout so the page doesn't jump when data lands.
  Widget _loadingScaffold() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2),
        automaticallyImplyLeading: false,
      ),
      body: const CurvedProfileHeader(
        color: providerBrandBlue,
        headerColors: [providerBrandDark, providerBrandBlue],
        headerHeight: _headerHeight,
        avatarRadius: _avatarRadius,
        bodyColor: kProfileBody,
        avatar: CircleAvatar(backgroundColor: Color(0xFFE3E9F2)),
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, _avatarRadius + 20, 20, 24),
          child: ProfileSkeleton(),
        ),
      ),
    );
  }

  void _showVerifiedSheet(DateTime? verifiedOn) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: providerBrandBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.verified_rounded,
                    color: providerBrandBlue, size: 30),
              ),
              const SizedBox(height: 14),
              const Text('Verified provider',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14213D))),
              const SizedBox(height: 8),
              Text(
                verifiedOn != null
                    ? 'Your CNIC and documents were checked and approved on ${formatLocalDateTime(verifiedOn, kDatePattern)}. Customers see this badge next to your name.'
                    : 'Your CNIC and documents were checked and approved. Customers see this badge next to your name.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final dashboard = context.watch<ProviderDashboardProvider>();
    final detail = dashboard.providerDetail;
    final documents = context.watch<ProviderDocumentProvider>();
    final profilePhotoUrl = documents.profilePhotoUrl;

    if (dashboard.profileLoading && detail == null) {
      return _loadingScaffold();
    }

    if (dashboard.profileError != null && detail == null) {
      return Scaffold(
        body: TabStatePlaceholder(
          icon: Icons.wifi_off_rounded,
          color: Colors.red,
          title: 'Couldn\'t load profile',
          message: dashboard.profileError,
          onRetry: _loadProfile,
        ),
      );
    }

    if (detail == null) {
      return Scaffold(
        body: TabStatePlaceholder(
          icon: Icons.person_off_outlined,
          color: providerBrandBlue,
          title: 'No profile data found',
          onRetry: _loadProfile,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2),
        automaticallyImplyLeading: false,
        actions: [ProfileLogoutButton(onPressed: () => _logout(context))],
      ),
      body: CurvedProfileHeader(
        color: providerBrandBlue,
        headerColors: const [providerBrandDark, providerBrandBlue],
        headerHeight: _headerHeight,
        avatarRadius: _avatarRadius,
        onRefresh: () async => _loadProfile(),
        bodyColor: kProfileBody,
        avatar: CircleAvatar(
          backgroundColor: providerBrandBlue,
          backgroundImage:
              profilePhotoUrl != null ? NetworkImage(profilePhotoUrl) : null,
          child: profilePhotoUrl == null
              ? const Icon(Icons.person, color: Colors.white, size: 42)
              : null,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, _avatarRadius + 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: staggerProfile(context, [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      detail.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14213D),
                          letterSpacing: -0.2),
                    ),
                  ),
                  if (documents.isVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Verified provider',
                        onPressed: () => _showVerifiedSheet(documents.verifiedOn),
                        icon: const Icon(Icons.verified_rounded,
                            color: providerBrandBlue, size: 22),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(detail.categoryName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              ProfileStatStrip(
                accent: providerBrandBlue,
                stats: [
                  ProfileStat(
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                      value: detail.totalReviews > 0
                          ? detail.averageRating.toStringAsFixed(1)
                          : 'New',
                      label: '${detail.totalReviews} reviews'),
                  ProfileStat(
                      icon: Icons.task_alt_rounded,
                      color: kProfileTeal,
                      value: '${detail.totalJobsCompleted}',
                      label: 'Jobs done'),
                  ProfileStat(
                      icon: Icons.work_history_rounded,
                      color: kProfileViolet,
                      value: '${detail.experienceYears} yrs',
                      label: 'Experience'),
                ],
              ),
              if (!documents.isVerified) ...[
                const SizedBox(height: 14),
                _VerificationBanner(remarks: documents.verificationRemarks),
              ],
              const SizedBox(height: 22),
              const ProfileSectionTitle('Availability'),
              ProfileCard(
                children: [
                  ListTile(
                    leading: Icon(
                        dashboard.isOnline
                            ? Icons.wifi_tethering_rounded
                            : Icons.wifi_tethering_off_rounded,
                        color: dashboard.isOnline ? Colors.green : Colors.grey),
                    title: Text(dashboard.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(dashboard.isOnline
                        ? 'Receiving new requests'
                        : 'Not receiving requests'),
                    trailing: dashboard.availabilityLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Switch(
                            value: dashboard.isOnline,
                            activeThumbColor: Colors.green,
                            onChanged: (v) =>
                                toggleProviderOnlineStatus(context, v),
                          ),
                  ),
                  ProfileDetailRow(
                    icon: Icons.schedule_rounded,
                    label: dashboard.isOnline
                        ? 'Available timing (tap to change)'
                        : 'Available timing',
                    color: kProfileCoral,
                    onTap: dashboard.isOnline
                        ? () => editProviderAvailableTiming(context)
                        : null,
                    value: dashboard.availableTiming ??
                        detail.availableTiming ??
                        'Not set',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ProfileActionTile(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      color: providerBrandBlue,
                      onTap: () => Navigator.of(context)
                          .pushNamed(ProviderRoutes.editProfile),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProfileActionTile(
                      icon: Icons.badge_outlined,
                      label: 'My Documents',
                      color: kProfileTeal,
                      onTap: () => Navigator.of(context)
                          .pushNamed(ProviderRoutes.verificationDocuments),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ProfileActionTile(
                      icon: Icons.category_rounded,
                      label: 'Categories',
                      color: kProfileViolet,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CategoriesAndTitlesScreen())),
                    ),
                  ),
                ],
              ),
              if (detail.description.isNotEmpty) ...[
                const SizedBox(height: 22),
                const ProfileSectionTitle('About'),
                ProfileCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(detail.description,
                          style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              color: Color(0xFF14213D))),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              const ProfileSectionTitle('Personal details'),
              ProfileCard(
                children: [
                  ProfileDetailRow(
                      icon: Icons.phone_rounded,
                      label: 'Mobile number',
                      value: detail.mobileNo,
                      copyable: true,
                      color: kProfileTeal),
                  if (detail.city != null && detail.city!.isNotEmpty)
                    ProfileDetailRow(
                        icon: Icons.location_city_rounded,
                        label: 'City',
                        value: detail.city!,
                        color: kProfileTeal),
                  ProfileDetailRow(
                      icon: Icons.wc_rounded,
                      label: 'Gender',
                      value: detail.gender,
                      color: kProfileViolet),
                  ProfileSecretRow(
                      icon: Icons.credit_card_rounded,
                      label: 'CNIC',
                      value: detail.cnic,
                      maskedValue: maskCnic(detail.cnic),
                      color: kProfileViolet),
                  ProfileDetailRow(
                      icon: Icons.category_rounded,
                      label: 'Main category',
                      value: detail.categoryName,
                      color: kProfileAmber),
                  ProfileDetailRow(
                      icon: Icons.event_rounded,
                      label: 'Member since',
                      value:
                          formatLocalDateTime(detail.createdOn, kDatePattern),
                      color: kProfileCoral),
                ],
              ),
              const SizedBox(height: 22),
              const ProfileSectionTitle('Preferences'),
              Consumer<TimeFormatProvider>(
                builder: (context, timeFormat, _) {
                  return ProfileCard(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.schedule_rounded,
                            color: kProfileCoral),
                        title: const Text('24-hour time'),
                        subtitle: Text(timeFormat.use24Hour
                            ? 'e.g. 14:30'
                            : 'e.g. 2:30 PM'),
                        value: timeFormat.use24Hour,
                        activeThumbColor: providerBrandBlue,
                        onChanged: (v) => timeFormat.setUse24Hour(v),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ProfileIdsDrawer(
                color: const Color(0xFF64748B),
                entries: {
                  if (currentUser != null) ...{
                    'Account type': currentUser.role,
                    'User ID': '${currentUser.userId}',
                  },
                  'Provider ID': '${detail.uid}',
                  'Category ID': '${detail.categoryId}',
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: kProminentFilledButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Switch to Customer'),
                // pushReplacementNamed: don't leave the provider dashboard
                // on the stack to pop back into with stale data — switching
                // back the other way uses the mirrored "Switch to Provider"
                // button, which rebuilds it fresh.
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(HomeScreen.routeName),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Contact Us'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(ContactUsScreen.routeName),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon:
                      Icon(Icons.privacy_tip_outlined, color: Colors.grey[600]),
                  onPressed: () => openPrivacyPolicy(context),
                  label: Text('Privacy Policy',
                      style: TextStyle(color: Colors.grey[600])),
                ),
              ),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: Colors.red, size: 20),
                  onPressed: () => _deleteAccount(context),
                  label: const Text('Delete Account',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Shown only while the provider is unverified: says what is happening and
/// surfaces any admin remarks, instead of burying it in a details row.
class _VerificationBanner extends StatelessWidget {
  final String? remarks;
  const _VerificationBanner({this.remarks});

  @override
  Widget build(BuildContext context) {
    final hasRemarks = remarks != null && remarks!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verification pending',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF14213D))),
                const SizedBox(height: 2),
                Text(hasRemarks ? remarks! : 'We are reviewing your documents.',
                    style: const TextStyle(
                        fontSize: 13, height: 1.35, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
