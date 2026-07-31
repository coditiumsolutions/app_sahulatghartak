import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/provider_profile_model.dart';
import '../services/provider_profile_api_service.dart';
import '../widgets/bottom_nav.dart';

class ServiceProvidersScreen extends StatefulWidget {
  static const routeName = '/service-providers';
  const ServiceProvidersScreen({super.key});

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  final _apiService = ProviderProfileApiService();
  late Future<List<ProviderProfileModel>> _providersFuture;
  Category? _category;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_category == null) {
      _category = ModalRoute.of(context)!.settings.arguments as Category;
      _providersFuture = _apiService.fetchByCategory(_category!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_category?.name ?? 'Service Providers'), backgroundColor: const Color(0xFF0078D4)),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: -1),
      body: FutureBuilder<List<ProviderProfileModel>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Failed to load service providers: ${snapshot.error}', textAlign: TextAlign.center)));
          }
          final providers = snapshot.data ?? [];
          if (providers.isEmpty) {
            return const Center(child: Text('No service providers found for this category.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ProviderCard(provider: providers[index]),
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ProviderProfileModel provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.person, size: 30, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(provider.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      if (provider.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(provider.rating.toStringAsFixed(1)),
                      const SizedBox(width: 12),
                      Text('${provider.experienceYears} yrs experience'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
