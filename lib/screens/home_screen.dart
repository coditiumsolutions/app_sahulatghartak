import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/service_provider.dart';
import '../utils/main_categories.dart';
import '../widgets/featured_services_carousel.dart';
import '../widgets/main_category_card.dart';
import 'subcategories_screen.dart';

import '../widgets/bottom_nav.dart';

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

  /// True when hosted inside [MainNavigationShell], which already provides
  /// the bottom navigation bar.
  final bool embedded;

  const HomeScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);
  static const _brandAccent = Color(0xFF4FC3F7);
  static const _ink = Color(0xFF14213D);

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services;
    final filteredServices = services.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final query = _searchQuery.toLowerCase();
    final filteredMainCategories = mainCategories.where((c) {
      if (query.isEmpty) return true;
      if (c.title.toLowerCase().contains(query)) return true;
      return c.subCategories.any((s) => s.label.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(176),
        child: _HomeHeader(
          query: _searchQuery,
          onQueryChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
      bottomNavigationBar: widget.embedded ? null : const AppBottomNavigation(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(title: 'Services'),
            const SizedBox(height: 12),
            if (filteredMainCategories.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No matching services')))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: filteredMainCategories.length,
                itemBuilder: (context, index) {
                  final category = filteredMainCategories[index];
                  return MainCategoryCard(
                    category: category,
                    onTap: () => Navigator.of(context).pushNamed(SubCategoriesScreen.routeName, arguments: category),
                  );
                },
              ),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            const _SectionHeader(title: 'Featured Services'),
            const SizedBox(height: 12),
            FeaturedServicesCarousel(services: filteredServices.take(4).toList(), cardColors: _cardColors),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Customer Reviews'),
            const SizedBox(height: 12),
            Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: const [ListTile(title: Text('Excellent service'), subtitle: Text('Quick and professional.')), ListTile(title: Text('Very satisfied'), subtitle: Text('Will use again.'))]))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Gradient brand header for the home screen — logo badge, greeting, and a
/// floating search field that overlaps the seam with the page body.
class _HomeHeader extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;

  const _HomeHeader({required this.query, required this.onQueryChanged});

  static const _brandDark = _HomeScreenState._brandDark;
  static const _brandBlue = _HomeScreenState._brandBlue;
  static const _brandAccent = _HomeScreenState._brandAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandDark, _brandBlue],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x330A4FA8), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _brandAccent.withOpacity(0.14)),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3))],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sahulat Ghar Tak',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Quality Services Delivered to Your Doorstep',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: TextField(
                        onChanged: onQueryChanged,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search services...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search_rounded, color: _brandBlue),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
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
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(color: _HomeScreenState._brandBlue, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _HomeScreenState._ink, letterSpacing: -0.2),
        ),
      ],
    );
  }
}
