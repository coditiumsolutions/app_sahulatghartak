import 'package:flutter/material.dart';

const Map<String, IconData> _keywordIcons = {
  'electric': Icons.electrical_services,
  'plumb': Icons.plumbing,
  'carpenter': Icons.handyman,
  'carpainter': Icons.handyman, // common misspelling of "carpenter" in source data
  'paint': Icons.format_paint,
  'sofa': Icons.chair,
  'carpet': Icons.layers,
  'kitchen': Icons.kitchen,
  'pest': Icons.bug_report,
  'insect': Icons.grass,
  'spray': Icons.grass,
  'evaluation': Icons.description,
  'certificate': Icons.description,
  'water tank': Icons.water,
  'solar': Icons.wb_sunny,
  'beautician': Icons.brush,
  'salon': Icons.brush,
  'hajj': Icons.airplanemode_active,
  'umrah': Icons.airplanemode_active,
  'maid': Icons.cleaning_services,
  'tutor': Icons.menu_book,
  'pack': Icons.local_shipping,
  'mover': Icons.local_shipping,
  'shifting': Icons.local_shipping,
  'vet': Icons.pets,
  'pet': Icons.pets,
  'clean': Icons.cleaning_services,
  'ac ': Icons.ac_unit,
  'air condition': Icons.ac_unit,
  'appliance': Icons.kitchen,
  'gardening': Icons.yard,
  'garden': Icons.yard,
  'security': Icons.security,
  'cctv': Icons.videocam,
  'driver': Icons.drive_eta,
  'cook': Icons.restaurant,
  'laundry': Icons.local_laundry_service,
  'fumigation': Icons.bug_report,
  'termite': Icons.pest_control,
  'tanker': Icons.local_shipping,
  'rent': Icons.key,
  'sale': Icons.sell,
  'purchase': Icons.shopping_cart,
  'renovat': Icons.construction,
  'lawyer': Icons.gavel,
  'legal': Icons.gavel,
};

IconData getCategoryIcon(String categoryName) {
  final name = categoryName.toLowerCase();
  for (final entry in _keywordIcons.entries) {
    if (name.contains(entry.key)) return entry.value;
  }
  return Icons.category;
}
