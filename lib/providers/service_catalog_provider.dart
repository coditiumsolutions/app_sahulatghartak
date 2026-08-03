import 'package:flutter/material.dart';

import '../models/service_catalog.dart';
import '../services/service_catalog_api_service.dart';

class ServiceCatalogProvider extends ChangeNotifier {
  final ServiceCatalogApiService _apiService = ServiceCatalogApiService();

  List<ServiceCatalog> _services = [];
  bool _isLoading = false;
  String? _error;

  ServiceCatalogProvider() {
    fetchServices();
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
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
