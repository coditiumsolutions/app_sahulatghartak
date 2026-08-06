import 'package:flutter/material.dart';

import '../models/service_title.dart';
import '../services/service_title_api_service.dart';

class ServiceTitleProvider extends ChangeNotifier {
  final ServiceTitleApiService _apiService = ServiceTitleApiService();

  List<ServiceTitle> _serviceTitles = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceTitle> get serviceTitles => List.unmodifiable(_serviceTitles);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadServiceTitles(int categoryUid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceTitles = await _apiService.fetchServiceTitles(categoryUid: categoryUid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
