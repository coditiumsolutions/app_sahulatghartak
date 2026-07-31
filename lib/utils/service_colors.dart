import 'package:flutter/material.dart';

/// Shared palette used to give each service a stable, distinct accent color
/// (e.g. on the featured carousel and the service detail Hero) when no
/// specific category color is available.
const List<Color> serviceCardColors = [
  Color(0xFFFF6B6B),
  Color(0xFF4ECDC4),
  Color(0xFF45B7D1),
  Color(0xFFFFA07A),
  Color(0xFF98D8C8),
  Color(0xFFF7DC6F),
  Color(0xFFBB8FCE),
  Color(0xFF85C1E2),
];

/// Deterministic color for a given service id, stable across screens.
Color colorForServiceId(int id) => serviceCardColors[id % serviceCardColors.length];
