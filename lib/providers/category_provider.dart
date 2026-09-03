import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/category_repository.dart';
import '../models/category.dart';
import '../utils/api_error.dart';

/// Holds the app-wide, always-unscoped category list (used e.g. for the home
/// screen's search suggestions). Screens that need categories scoped to a
/// single service (like [SubCategoriesScreen]) fetch their own copy directly
/// via [CategoryApiService] instead of sharing this provider — see the note
/// on [SubCategoriesScreen] for why sharing a single mutable list across
/// concurrently-fetching screens caused categories from one service to
/// briefly appear under another.
class CategoryProvider extends ChangeNotifier {
  CategoryProvider({required CategoryRepository repository}) : _repository = repository {
    // Deferred: lazy ChangeNotifierProvider construction can happen mid-build
    // (first context.watch/read call), and notifyListeners() firing
    // synchronously from a constructor while a widget's build() is still on
    // the stack triggers "setState() called during build".
    scheduleMicrotask(fetchCategories);
  }

  final CategoryRepository _repository;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _repository.fetchCategories();
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
