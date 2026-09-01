import 'dart:async';

import 'package:flutter/material.dart';

import '../models/service_catalog.dart';
import '../services/service_catalog_api_service.dart';
import '../utils/api_error.dart';

class ServiceCatalogProvider extends ChangeNotifier {
  final ServiceCatalogApiService _apiService = ServiceCatalogApiService();

  List<ServiceCatalog> _services = [];
  bool _isLoading = false;
  String? _error;

  ServiceCatalogProvider() {
    // Deferred: lazy ChangeNotifierProvider construction can happen mid-build
    // (first context.watch/read call), and notifyListeners() firing
    // synchronously from a constructor while a widget's build() is still on
    // the stack triggers "setState() called during build".
    scheduleMicrotask(fetchServices);
  }

  List<ServiceCatalog> get services => List.unmodifiable(_services);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _apiService.fetchServices();
      _services.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
