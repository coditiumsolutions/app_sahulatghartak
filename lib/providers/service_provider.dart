import 'dart:async';

import 'package:flutter/material.dart';
import '../models/service.dart';

class ServiceProvider extends ChangeNotifier {
  final List<Service> _services = [];

  ServiceProvider() {
    // Deferred: lazy ChangeNotifierProvider construction can happen mid-build
    // (first context.watch/read call), and notifyListeners() firing
    // synchronously from a constructor while a widget's build() is still on
    // the stack triggers "setState() called during build".
    scheduleMicrotask(_loadServices);
  }

  List<Service> get services => List.unmodifiable(_services);

  void _loadServices() {
    final entries = <Service>[
      const Service(id: 1, name: 'Electrician Services', description: 'Wiring, repairs, installations', startingPrice: 500.0, iconData: Icons.electrical_services, imagePath: 'assets/electrician01.jpeg'),
      const Service(id: 2, name: 'Plumbing Services', description: 'Pipes, leaks, faucets', startingPrice: 600.0, iconData: Icons.plumbing, imagePath: 'assets/plumbing01.jpeg'),
      const Service(id: 3, name: 'Carpenter Services', description: 'Woodwork, furniture', startingPrice: 800.0, iconData: Icons.handyman, imagePath: 'assets/carpanter01.jpg'),
      const Service(id: 4, name: 'Paint Services', description: 'Interior & exterior painting', startingPrice: 1200.0, iconData: Icons.format_paint, imagePath: 'assets/painter01.jpg'),
      const Service(id: 5, name: 'Sofa Cleaning', description: 'Deep sofa cleaning', startingPrice: 400.0, iconData: Icons.chair),
      const Service(id: 6, name: 'Carpet Cleaning', description: 'Deep carpet wash', startingPrice: 450.0, iconData: Icons.layers),
      const Service(id: 7, name: 'Kitchen Cleaning Services', description: 'Complete kitchen sanitation', startingPrice: 700.0, iconData: Icons.kitchen),
      const Service(id: 8, name: 'Pest Control (Termite Spray)', description: 'Termite and pest control', startingPrice: 1500.0, iconData: Icons.bug_report),
      const Service(id: 9, name: 'Insect Spray Services', description: 'Mosquito & insect spray', startingPrice: 500.0, iconData: Icons.grass),
      const Service(id: 10, name: 'Property Evaluation Certificates', description: 'Property reports & certificates', startingPrice: 2500.0, iconData: Icons.description),
      const Service(id: 11, name: 'Water Tank Cleaning', description: 'Water tank sanitation', startingPrice: 900.0, iconData: Icons.water),
      const Service(id: 12, name: 'Solar Panel Cleaning', description: 'Solar panel maintenance', startingPrice: 1800.0, iconData: Icons.wb_sunny),
      const Service(id: 13, name: 'Beautician Services', description: 'At-home beauty services', startingPrice: 1000.0, iconData: Icons.brush),
      const Service(id: 14, name: 'Hajj & Umrah Services', description: 'Pilgrimage facilitation', startingPrice: 5000.0, iconData: Icons.airplanemode_active),
      const Service(id: 15, name: 'Maid Provider', description: 'Professional maid services', startingPrice: 1200.0, iconData: Icons.cleaning_services),
      const Service(id: 16, name: 'Tutor Provider', description: 'Home tutors for all subjects', startingPrice: 800.0, iconData: Icons.menu_book),
      const Service(id: 17, name: 'Packers & Movers (Home Shifting)', description: 'Packing & moving services', startingPrice: 3000.0, iconData: Icons.local_shipping),
      const Service(id: 18, name: 'Pets Veterinary Services', description: 'Pet health & vaccination', startingPrice: 700.0, iconData: Icons.pets),
    ];
    _services.addAll(entries);
    notifyListeners();
  }
}
