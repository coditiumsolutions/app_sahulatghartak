import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryApiService _apiService = CategoryApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider() {
    fetchCategories();
  }

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches categories. Pass [serviceUid] to scope to a single parent
  /// service; omit to fetch the full flat list (used e.g. by the provider
  /// registration category dropdown, which spans all services).
  Future<void> fetchCategories({int? serviceUid}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.fetchCategories(serviceUid: serviceUid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
