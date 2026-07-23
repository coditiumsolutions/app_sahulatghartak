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
import 'service_requests_screen.dart';

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
  static const double _headerHeight = 75;

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
      appBar: AppBar(
        title: const Text('Customer Profile'),
        backgroundColor: const Color(0xFF0078D4),
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: () => _logout(context))],
      ),
      bottomNavigationBar: widget.embedded ? null : const AppBottomNavigation(currentIndex: 4),
      body: CurvedProfileHeader(
        color: kPrimaryColor,
        headerHeight: _headerHeight,
        avatarRadius: _avatarRadius,
        onRefresh: () async => _loadAddresses(),
        avatar: CircleAvatar(
          backgroundColor: kPrimaryColor,
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 32, color: Colors.white),
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                user.mobileNo,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withOpacity(0.5)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.account_circle,
                      label: 'ACCOUNT TYPE',
                      value: user.role,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.tag,
                      label: 'USER ID',
                      value: '${user.userId}',
                      color: kSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(kPrimaryColor),
                onPressed: () => Navigator.of(context).pushNamed(ServiceRequestsScreen.routeName),
                icon: const Icon(Icons.assignment),
                label: const Text('My Service Requests'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Addresses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AddAddressScreen.routeName),
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Add Address'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (addressState.loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()))
              else if (addressState.error != null)
                Text(addressState.error!, style: const TextStyle(color: Colors.red))
              else if (addressState.addresses.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No addresses added yet.'))
              else
                Card(
                  child: Column(
                    children: [
                      for (final address in addressState.addresses) ...[
                        ListTile(
                          leading: const Icon(Icons.location_on, color: kPrimaryColor),
                          title: Text(address.addressTitle),
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
                  style: kProminentFilledButtonStyle(kSecondaryColor),
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () => Navigator.of(context).pushNamed(ProviderDashboardScreen.routeName),
                  label: const Text('Switch to Provider'),
                )
              else
                ElevatedButton.icon(
                  style: kProminentFilledButtonStyle(kSecondaryColor),
                  icon: const Icon(Icons.engineering),
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
