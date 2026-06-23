import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/service_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/featured_services_carousel.dart';

import '../widgets/bottom_nav.dart';
import 'landing_screen.dart';

const List<Color> _cardColors = [
  Color(0xFFFF6B6B),
  Color(0xFF4ECDC4),
  Color(0xFF45B7D1),
  Color(0xFFFFA07A),
  Color(0xFF98D8C8),
  Color(0xFFF7DC6F),
  Color(0xFFBB8FCE),
  Color(0xFF85C1E2),
];

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    final filteredServices = services.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;
    final filteredCategories = categories.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final pages = (filteredCategories.length / 6).ceil();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0078D4),
        iconTheme: const IconThemeData(color: Colors.black),
        toolbarHeight: 160,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
            },
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sahulat Ghar Tak',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(height: 8),
            Text('Quality Services Delivered to Your Doorstep', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text('Services', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: categoryProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : categoryProvider.error != null
                      ? Center(child: Text('Failed to load categories: ${categoryProvider.error}'))
                      : pages == 0
                          ? const SizedBox.shrink()
                          : PageView.builder(
                controller: PageController(initialPage: pages * 1000),
                itemBuilder: (context, pageIndex) {
                  final actualPage = pageIndex % pages;
                  final start = actualPage * 6;
                  final end = (start + 6).clamp(0, filteredCategories.length);
                  final slice = filteredCategories.sublist(start, end);
                  return GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(8),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: slice.map((category) {
                      final index = categories.indexOf(category);
                      final color = _cardColors[index % _cardColors.length];
                      return CategoryCard(category: category, backgroundColor: color);
                    }).toList(),
                  );
                },
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            Text('Featured Services', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FeaturedServicesCarousel(services: filteredServices.take(4).toList(), cardColors: _cardColors),
            const SizedBox(height: 24),
            Text('Customer Reviews', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: const [ListTile(title: Text('Excellent service'), subtitle: Text('Quick and professional.')), ListTile(title: Text('Very satisfied'), subtitle: Text('Will use again.'))]))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
