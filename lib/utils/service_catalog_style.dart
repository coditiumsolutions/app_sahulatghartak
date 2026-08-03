import 'package:flutter/material.dart';

/// Icon/color styling for parent [ServiceCatalog] entries. The backend has
/// no icon/color fields, so the home screen's visual identity for each
/// service is looked up here by name, with a stable fallback for anything
/// not explicitly listed (e.g. newly added services).
class ServiceCatalogStyle {
  final IconData icon;
  final Color color;
  const ServiceCatalogStyle(this.icon, this.color);
}

const Map<String, ServiceCatalogStyle> _styleByName = {
  'home maintenance': ServiceCatalogStyle(Icons.home_repair_service, Color(0xFF45B7D1)),
  'specialized services': ServiceCatalogStyle(Icons.design_services, Color(0xFFBB8FCE)),
  'property & legal services': ServiceCatalogStyle(Icons.real_estate_agent, Color(0xFFF7DC6F)),
  'sahulat ride': ServiceCatalogStyle(Icons.local_taxi, Color(0xFFFF9F43)),
};

const _fallbackStyles = [
  ServiceCatalogStyle(Icons.miscellaneous_services, Color(0xFF4ECDC4)),
  ServiceCatalogStyle(Icons.category, Color(0xFF6C5CE7)),
];

ServiceCatalogStyle styleForServiceName(String name, int fallbackIndex) {
  final match = _styleByName[name.trim().toLowerCase()];
  if (match != null) return match;
  return _fallbackStyles[fallbackIndex % _fallbackStyles.length];
}
