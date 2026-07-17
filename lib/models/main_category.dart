import 'package:flutter/material.dart';

/// A subcategory display label paired with the keywords used to match it
/// against real backend [Category] names (see [utils/main_categories.dart]).
class SubCategoryItem {
  final String label;
  final List<String> keywords;
  const SubCategoryItem(this.label, this.keywords);
}

/// A client-side grouping of backend service categories. The backend has no
/// concept of "main category" - this taxonomy exists purely to organize the
/// home screen; actual service requests still reference the real backend
/// [Category] matched via [SubCategoryItem.keywords].
class MainCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<SubCategoryItem> subCategories;

  const MainCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.subCategories,
  });
}
