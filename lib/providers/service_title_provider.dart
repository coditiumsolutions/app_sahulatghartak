import 'package:flutter/material.dart';

import '../models/service_title.dart';
import '../services/service_title_api_service.dart';

class ServiceTitleProvider extends ChangeNotifier {
  final ServiceTitleApiService _apiService = ServiceTitleApiService();

  List<ServiceTitle> _serviceTitles = [];
  bool _isLoading = false;
  String? _error;

  // This provider is a single app-wide instance, so a slower request for a
  // previous category could otherwise resolve after a newer one and
  // overwrite it with the wrong category's titles. Only the response
  // matching the most recently *started* call is applied.
  int _requestId = 0;

  List<ServiceTitle> get serviceTitles => List.unmodifiable(_serviceTitles);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadServiceTitles(int categoryUid) async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.fetchServiceTitles(categoryUid: categoryUid);
      if (requestId != _requestId) return;
      _serviceTitles = result;
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
