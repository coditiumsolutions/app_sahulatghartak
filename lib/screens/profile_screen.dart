import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client_address.dart';
import '../providers/auth_provider.dart';
import '../providers/client_address_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/curved_profile_header.dart';
import 'add_address_screen.dart';
import 'landing_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_registration_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  /// True when hosted inside [MainNavigationShell], which already provides
  /// the bottom navigation bar.
  final bool embedded;

  const ProfileScreen({Key? key, this.embedded = false}) : super(key: key);

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.addressTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final addressProvider = context.read<ClientAddressProvider>();
    final success = await addressProvider.deleteAddress(address.uid);
    if (!mounted) return;

    final message = success ? 'Address deleted' : (addressProvider.error ?? 'Failed to delete address');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final addressState = context.watch<ClientAddressProvider>();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
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
                style: TextStyle(color: Colors.black.withOpacity(0.45), fontWeight: FontWeight.w500),
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
                  boxShadow: [BoxShadow(color: _brandDark.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
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
                      shadowColor: _brandBlue.withOpacity(0.4),
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
                Text(addressState.error!, style: const TextStyle(color: Colors.red))
              else if (addressState.addresses.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: _brandDark.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: Text('No addresses added yet.', style: TextStyle(color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w500)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: _brandDark.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      for (final address in addressState.addresses) ...[
                        ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(color: _brandBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
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
                  onPressed: () => Navigator.of(context).pushNamed(ProviderDashboardScreen.routeName),
                  label: const Text('Switch to Provider'),
                )
              else
                ElevatedButton.icon(
                  style: kProminentFilledButtonStyle(_brandBlue),
                  icon: const Icon(Icons.engineering_rounded),
                  onPressed: () => Navigator.of(context).pushNamed(ProviderRegistrationScreen.routeName),
                  label: const Text('Become a Provider'),
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
