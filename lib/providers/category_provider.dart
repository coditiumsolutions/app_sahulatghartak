import 'dart:async';

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryApiService _apiService = CategoryApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Guards against out-of-order responses: the app-wide initial fetch (no
  // serviceUid, fired from the constructor) and a screen-scoped fetch (with
  // serviceUid) can both be in flight at once, and whichever resolves last
  // used to win — sometimes overwriting a scoped result with the full
  // unfiltered list. Only the response matching the most recently *started*
  // call is applied.
  int _requestId = 0;

  CategoryProvider() {
    // Deferred: lazy ChangeNotifierProvider construction can happen mid-build
    // (first context.watch/read call), and notifyListeners() firing
    // synchronously from a constructor while a widget's build() is still on
    // the stack triggers "setState() called during build".
    scheduleMicrotask(fetchCategories);
  }

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches categories. Pass [serviceUid] to scope to a single parent
  /// service; omit to fetch the full flat list (used e.g. by the provider
  /// registration category dropdown, which spans all services).
  Future<void> fetchCategories({int? serviceUid}) async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.fetchCategories(serviceUid: serviceUid);
      if (requestId != _requestId) return;
      _categories = result;
    } catch (e) {
      if (requestId != _requestId) return;
      _error = e.toString();
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
