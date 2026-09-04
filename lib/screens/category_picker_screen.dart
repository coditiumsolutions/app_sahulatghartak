import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_api_service.dart';
import '../utils/api_error.dart';
import '../utils/category_icons.dart';
import '../utils/service_catalog_style.dart';
import '../widgets/decorative_glow_circle.dart';

// Shared brand gradient used across the app's other branded headers (home
// screen, service request detail) — kept local since it's just a palette,
// not shared behavior.
const _brandDark = Color(0xFF0A4FA8);
const _brandBlue = Color(0xFF016EE3);
const _brandAccent = Color(0xFF4FC3F7);

/// Full-screen category picker for the provider registration form.
///
/// Fetches the complete category list itself (always unscoped, no
/// `serviceUid` filter) instead of reading the shared [CategoryProvider] —
/// that provider is also mutated by other screens (e.g. Home ->
/// Subcategories scopes it to a single service), so reading it here could
/// silently show whichever service was last browsed elsewhere in the app.
/// Owning its own request keeps this screen correct regardless of
/// navigation history.
class CategoryPickerScreen extends StatefulWidget {
  static const routeName = '/register-provider/category-picker';

  final int? selectedCategoryId;

  const CategoryPickerScreen({super.key, this.selectedCategoryId});

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  final _apiService = CategoryApiService();
  final _searchController = TextEditingController();

  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _apiService.fetchCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<Category>> get _groupedFiltered {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _categories
        : _categories.where((c) => c.name.toLowerCase().contains(query) || c.serviceName.toLowerCase().contains(query)).toList();

    final groups = <String, List<Category>>{};
    for (final category in filtered) {
      groups.putIfAbsent(category.serviceName, () => []).add(category);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedFiltered;
    final groupNames = groups.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Column(
        children: [
          _PickerHeader(
            controller: _searchController,
            query: _query,
            onQueryChanged: (v) => setState(() => _query = v),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : groupNames.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: groupNames.length,
                            itemBuilder: (context, index) {
                              final serviceName = groupNames[index];
                              final style = styleForServiceName(serviceName, index);
                              return _CategoryGroupSection(
                                serviceName: serviceName,
                                style: style,
                                categories: groups[serviceName]!,
                                selectedCategoryId: widget.selectedCategoryId,
                                onSelected: (category) => Navigator.of(context).pop(category),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// Compact branded header (title + back button over a short gradient, plus a
/// floating search field) matching the app's other headers, e.g.
/// [request_detail_screen.dart]'s `_DetailHeader` — kept short since this
/// screen trades header space for list room to show 15+ categories at once.
class _PickerHeader extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  const _PickerHeader({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_brandDark, _brandBlue]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x330A4FA8), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: DecorativeGlowCircle(baseSize: 110, color: _brandAccent.withValues(alpha: 0.14)),
            ),
            const Positioned(
              bottom: -40,
              left: -16,
              child: DecorativeGlowCircle(baseSize: 90, color: Color.fromRGBO(255, 255, 255, 0.06)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Text(
                          'Select Your Category',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          controller: controller,
                          onChanged: onQueryChanged,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.search_rounded, color: _brandBlue),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 20),
                                    onPressed: onClear,
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
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

class _CategoryGroupSection extends StatelessWidget {
  final String serviceName;
  final ServiceCatalogStyle style;
  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<Category> onSelected;

  const _CategoryGroupSection({
    required this.serviceName,
    required this.style,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: style.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(9)),
                  child: Icon(style.icon, size: 17, color: style.color),
                ),
                const SizedBox(width: 10),
                Text(
                  serviceName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF14213D)),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                for (var i = 0; i < categories.length; i++) ...[
                  if (i != 0) const Divider(height: 1, indent: 60),
                  _CategoryTile(
                    category: categories[i],
                    color: style.color,
                    selected: categories[i].id == selectedCategoryId,
                    onTap: () => onSelected(categories[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
              child: Icon(getCategoryIcon(category.name), size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF14213D)),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color, size: 22) else const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No categories found', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text('Couldn\'t load categories', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
