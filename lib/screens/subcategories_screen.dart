import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/main_category.dart';
import '../providers/category_provider.dart';
import '../utils/category_icons.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/subcategory_card.dart';
import 'service_request_form_screen.dart';

class SubCategoriesScreen extends StatelessWidget {
  static const routeName = '/subcategories';
  const SubCategoriesScreen({Key? key}) : super(key: key);

  static const double _avatarRadius = 46;
  static const double _headerHeight = 170;

  Category? _findMatch(List<Category> categories, List<String> keywords) {
    for (final category in categories) {
      final name = category.name.toLowerCase();
      if (keywords.any((keyword) => name.contains(keyword))) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mainCategory = ModalRoute.of(context)!.settings.arguments as MainCategory;
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.categories;

    return Scaffold(
      backgroundColor: kPrimaryColor,
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
            ),
          ),
          Positioned(
            top: -30,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
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
                          decoration: BoxDecoration(shape: BoxShape.circle, color: mainCategory.color.withOpacity(0.1)),
                        ),
                      ),
                      Positioned(
                        bottom: -70,
                        left: -60,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: mainCategory.color.withOpacity(0.08)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, _avatarRadius + 24, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              mainCategory.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose a service to get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.5)),
                            ),
                            Expanded(
                              child: categoryProvider.isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : categoryProvider.error != null
                                      ? Center(child: Text('Failed to load services: ${categoryProvider.error}', textAlign: TextAlign.center))
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
                                                    itemCount: mainCategory.subCategories.length,
                                                    itemBuilder: (context, index) {
                                                      final subCategory = mainCategory.subCategories[index];
                                                      final match = _findMatch(categories, subCategory.keywords);
                                                      return SubCategoryCard(
                                                        label: subCategory.label,
                                                        icon: getCategoryIcon(subCategory.label),
                                                        color: mainCategory.color,
                                                        available: match != null,
                                                        onTap: () {
                                                          if (match != null) {
                                                            Navigator.of(context).pushNamed(ServiceRequestFormScreen.routeName, arguments: match);
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${subCategory.label} is coming soon')));
                                                          }
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  child: Icon(mainCategory.icon, color: Colors.white, size: 42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
