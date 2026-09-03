import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/service_catalog_repository.dart';
import '../models/service_catalog.dart';
import '../utils/api_error.dart';

class ServiceCatalogProvider extends ChangeNotifier {
  ServiceCatalogProvider({required ServiceCatalogRepository repository}) : _repository = repository {
    // Deferred: lazy ChangeNotifierProvider construction can happen mid-build
    // (first context.watch/read call), and notifyListeners() firing
    // synchronously from a constructor while a widget's build() is still on
    // the stack triggers "setState() called during build".
    scheduleMicrotask(fetchServices);
  }

  final ServiceCatalogRepository _repository;

  List<ServiceCatalog> _services = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceCatalog> get services => List.unmodifiable(_services);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _repository.fetchServices();
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
