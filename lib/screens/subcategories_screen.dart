import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service_catalog.dart';
import '../providers/category_provider.dart';
import '../utils/category_icons.dart';
import '../utils/service_catalog_style.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/subcategory_card.dart';
import 'service_request_form_screen.dart';

class SubCategoriesScreen extends StatefulWidget {
  static const routeName = '/subcategories';

  /// Optional explicit service, used when pushed directly (e.g. via
  /// [OpenContainer]). Falls back to the route arguments when navigated to
  /// via [Navigator.pushNamed].
  final ServiceCatalog? service;

  /// When set (i.e. hosted inside an [OpenContainer]), the back button calls
  /// this instead of [Navigator.maybePop] so the closing transform animation
  /// plays instead of a plain route pop.
  final VoidCallback? onClose;

  const SubCategoriesScreen({super.key, this.service, this.onClose});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  static const double _avatarRadius = 46;
  static const double _headerHeight = 170;

  ServiceCatalog? _service;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _service = widget.service ?? ModalRoute.of(context)!.settings.arguments as ServiceCatalog;
    context.read<CategoryProvider>().fetchCategories(serviceUid: _service!.id);
  }

  @override
  Widget build(BuildContext context) {
    final service = _service!;
    final style = styleForServiceName(service.name, 0);
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return PopScope(
      canPop: widget.onClose == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onClose?.call();
      },
      child: Scaffold(
      backgroundColor: style.color,
      bottomNavigationBar: const AppBottomNavigation(currentIndex: -1),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Positioned(
            top: -30,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: _headerHeight),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -60,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: style.color.withValues(alpha: 0.1)),
                        ),
                      ),
                      Positioned(
                        bottom: -70,
                        left: -60,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: style.color.withValues(alpha: 0.08)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, _avatarRadius + 24, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              service.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose a service to get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.5)),
                            ),
                            Expanded(
                              child: categoryProvider.isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : categoryProvider.error != null
                                      ? Center(child: Text('Failed to load services: ${categoryProvider.error}', textAlign: TextAlign.center))
                                      : categories.isEmpty
                                          ? const Center(child: Text('No services available yet.\nComing soon.', textAlign: TextAlign.center))
                                          : LayoutBuilder(
                                              builder: (context, constraints) {
                                                return SingleChildScrollView(
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                                    child: Center(
                                                      child: GridView.builder(
                                                        shrinkWrap: true,
                                                        physics: const NeverScrollableScrollPhysics(),
                                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3,
                                                          childAspectRatio: 0.85,
                                                          crossAxisSpacing: 12,
                                                          mainAxisSpacing: 12,
                                                        ),
                                                        itemCount: categories.length,
                                                        itemBuilder: (context, index) {
                                                          final category = categories[index];
                                                          return SubCategoryCard(
                                                            label: category.name,
                                                            icon: getCategoryIcon(category.name),
                                                            color: style.color,
                                                            available: true,
                                                            onTap: () {
                                                              Navigator.of(context).pushNamed(
                                                                ServiceRequestFormScreen.routeName,
                                                                arguments: ServiceRequestFormArgs(category: category, color: style.color),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: _headerHeight - _avatarRadius,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: _avatarRadius * 2,
                height: _avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: style.color,
                  child: Icon(style.icon, color: Colors.white, size: 42),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
