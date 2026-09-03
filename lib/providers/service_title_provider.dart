import 'package:flutter/material.dart';

import '../data/repositories/service_title_repository.dart';
import '../models/service_title.dart';
import '../utils/api_error.dart';

class ServiceTitleProvider extends ChangeNotifier {
  ServiceTitleProvider({required ServiceTitleRepository repository}) : _repository = repository;

  final ServiceTitleRepository _repository;

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
      final result = await _repository.fetchServiceTitles(categoryUid);
      if (requestId != _requestId) return;
      _serviceTitles = result;
    } catch (e) {
      if (requestId != _requestId) return;
      _error = friendlyErrorMessage(e);
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
