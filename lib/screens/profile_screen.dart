import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_address.dart';
import '../providers/auth_provider.dart';
import '../providers/client_address_provider.dart';
import '../utils/constants.dart';
import '../utils/privacy_policy_launcher.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/curved_profile_header.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/message_dialog.dart';
import 'add_address_screen.dart';
import 'customer_registration_screen.dart';
import 'edit_profile_screen.dart';
import 'landing_screen.dart';
import 'login_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  /// True when hosted inside [MainNavigationShell], which already provides
  /// the bottom navigation bar.
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _avatarRadius = 46;
  static const double _headerHeight = 150;

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);
  static const _brandAccent = Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddresses());
  }

  void _loadAddresses() {
    final clientUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (clientUid != null) {
      context.read<ClientAddressProvider>().loadAddresses(clientUid);
    }
  }

  void _editAddress(ClientAddress address) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAddressScreen(existing: address)));
  }

  Future<void> _deleteAddress(ClientAddress address) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Address',
      message: 'Are you sure you want to delete "${address.addressTitle}"? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      color: Colors.red,
    );
    if (confirmed != true || !mounted) return;

    final addressProvider = context.read<ClientAddressProvider>();
    final success = await addressProvider.deleteAddress(address.uid);
    if (!mounted) return;

    final message = success ? 'Address deleted' : (addressProvider.error ?? 'Failed to delete address');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your account?',
      confirmLabel: 'Log Out',
      icon: Icons.logout_rounded,
      color: kPrimaryColor,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
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
      Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
    } else {
      await showMessageDialog(
        context,
        title: 'Delete Failed',
        message: authProvider.error ?? 'Failed to delete account',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final addressState = context.watch<ClientAddressProvider>();

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        bottomNavigationBar: widget.embedded ? null : const AppBottomNavigation(currentIndex: 2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(color: _brandBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.person_outline_rounded, size: 36, color: _brandBlue),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'You\'re browsing as a guest',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF14213D)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in or create an account to save addresses, request services, and track your bookings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed(LoginScreen.routeName),
                      child: const Text('Log In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brandBlue,
                        side: BorderSide(color: _brandBlue.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed(CustomerRegistrationScreen.routeName),
                      child: const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      bottomNavigationBar: widget.embedded ? null : const AppBottomNavigation(currentIndex: 2),
      body: CurvedProfileHeader(
        color: _brandBlue,
        headerColors: const [_brandDark, _brandBlue],
        headerHeight: _headerHeight,
        avatarRadius: _avatarRadius,
        onRefresh: () async => _loadAddresses(),
        avatar: CircleAvatar(
          backgroundColor: _brandBlue,
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, _avatarRadius + 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                user.username,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF14213D), letterSpacing: -0.2),
              ),
              const SizedBox(height: 4),
              Text(
                user.mobileNo,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.verified_user_rounded,
                      label: 'ACCOUNT TYPE',
                      value: user.role,
                      color: _brandBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.tag_rounded,
                      label: 'USER ID',
                      value: '${user.userId}',
                      color: _brandAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    _InfoTile(label: 'Mobile Number', value: user.mobileNo),
                    if (user.categoryName != null) ...[
                      const Divider(height: 1),
                      _InfoTile(label: 'Category', value: user.categoryName!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(CustomerEditProfileScreen.routeName),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(foregroundColor: _brandBlue, side: BorderSide(color: _brandBlue.withValues(alpha: 0.4))),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Addresses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF14213D), letterSpacing: -0.2)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: _brandBlue.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed(AddAddressScreen.routeName),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (addressState.loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()))
              else if (addressState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Couldn\'t load addresses', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A2233))),
                      const SizedBox(height: 6),
                      Text(addressState.error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _loadAddresses,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(foregroundColor: _brandBlue, side: BorderSide(color: _brandBlue.withValues(alpha: 0.4))),
                      ),
                    ],
                  ),
                )
              else if (addressState.addresses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No addresses added yet', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A2233), fontSize: 14.5)),
                      const SizedBox(height: 4),
                      Text(
                        'Add one so providers know where to reach you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      for (final address in addressState.addresses) ...[
                        ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: _brandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
                            child: Icon(Icons.location_on_rounded, color: _brandBlue, size: 20),
                          ),
                          title: Text(address.addressTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${address.fullAddress}, ${address.area}, ${address.city}'),
                          trailing: addressState.deletingUid == address.uid
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') _editAddress(address);
                                    if (value == 'delete') _deleteAddress(address);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                                    PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                                  ],
                                ),
                        ),
                        if (address != addressState.addresses.last) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              if (user.role == 'Provider')
                ElevatedButton.icon(
                  style: kProminentFilledButtonStyle(_brandBlue),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  // pushReplacementNamed, not pushNamed: swapping dashboards
                  // should never leave a stale customer-dashboard instance
                  // underneath to pop back into (it wouldn't refresh itself
                  // on return). Switching back uses the mirrored button on
                  // the provider side, which rebuilds this screen fresh.
                  onPressed: () => Navigator.of(context).pushReplacementNamed(ProviderDashboardScreen.routeName),
                  label: const Text('Switch to Provider'),
                )
              else
                ElevatedButton.icon(
                  style: kProminentFilledButtonStyle(_brandBlue),
                  icon: const Icon(Icons.engineering_rounded),
                  onPressed: () => Navigator.of(context).pushNamed(ProviderRegistrationScreen.routeName),
                  label: const Text('Become a Provider'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(Colors.red),
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () => _deleteAccount(context),
                label: const Text('Delete Account'),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  icon: Icon(Icons.privacy_tip_outlined, color: Colors.grey[600]),
                  onPressed: () => openPrivacyPolicy(context),
                  label: Text('Privacy Policy', style: TextStyle(color: Colors.grey[600])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
