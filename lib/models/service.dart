import 'package:flutter/material.dart';

class Service {
  final int id;
  final String name;
  final String description;
  final double startingPrice;
  final IconData iconData;
  final String? imagePath;

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.startingPrice,
    required this.iconData,
    this.imagePath,
  });
}
