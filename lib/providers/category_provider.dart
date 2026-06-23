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

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _apiService.fetchCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
