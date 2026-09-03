import 'package:flutter/material.dart';

import '../data/repositories/customer_service_request_repository.dart';
import '../models/customer_service_request.dart';
import '../utils/api_error.dart';

class CustomerServiceRequestProvider extends ChangeNotifier {
  CustomerServiceRequestProvider({required CustomerServiceRequestRepository repository}) : _repository = repository;

  final CustomerServiceRequestRepository _repository;

  int? _clientUid;

  List<CustomerServiceRequest> _requests = [];
  List<CustomerServiceRequest> get requests => _requests;

  bool _loading = false;
  bool get loading => _loading;

  bool _saving = false;
  bool get saving => _saving;

  int? _deletingUid;
  int? get deletingUid => _deletingUid;

  int? _cancellingUid;
  int? get cancellingUid => _cancellingUid;

  String? _error;
  String? get error => _error;

  Future<void> loadRequests(int clientUid) async {
    _clientUid = clientUid;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _requests = await _repository.fetchByClient(clientUid);
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> getStoredPasscode(int requestUid) => _repository.getStoredPasscode(requestUid);

  Future<bool> createRequest({
    required int clientUid,
    required int categoryUid,
    required int clientAddressUid,
    required String serviceTitle,
    required String serviceDescription,
    required String preferredServiceDate,
    required String preferredServiceTime,
    required bool isUrgent,
    required String contactPerson,
    required String contactNo,
    double? estimatedBudget,
    String? remarks,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _repository.create(
        clientUid: clientUid,
        categoryUid: categoryUid,
        clientAddressUid: clientAddressUid,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        preferredServiceDate: preferredServiceDate,
        preferredServiceTime: preferredServiceTime,
        isUrgent: isUrgent,
        contactPerson: contactPerson,
        contactNo: contactNo,
        estimatedBudget: estimatedBudget,
        remarks: remarks,
      );
      _requests = [created, ..._requests];
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  CustomerServiceRequest? _selectedRequest;
  CustomerServiceRequest? get selectedRequest => _selectedRequest;

  bool _detailLoading = false;
  bool get detailLoading => _detailLoading;

  String? _detailError;
  String? get detailError => _detailError;

  /// Detail-screen selection state (architecture-audit.md §6 Task 7): fetches
  /// [requestUid], exposes it via [selectedRequest] while also merging it
  /// into [requests], so a future detail-screen split (Phase 3) can render
  /// from this ViewModel alone instead of seeding itself from a
  /// navigation-argument copy or keeping its own local `State`. Call
  /// [clearSelection] from the screen's `dispose()`.
  Future<void> selectRequest(int requestUid) async {
    _detailLoading = true;
    _detailError = null;
    notifyListeners();

    try {
      _selectedRequest = await fetchRequestById(requestUid);
    } catch (e) {
      _detailError = friendlyErrorMessage(e);
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedRequest = null;
    _detailLoading = false;
    _detailError = null;
  }

  /// Fetches a single request fresh from the API and merges it into
  /// [requests] (if present there), so any screen watching this provider —
  /// not just the caller — sees the update immediately. Without this, a
  /// detail screen's own pull-to-refresh would only ever update its local
  /// copy, leaving the main list showing stale data until its own refresh.
  Future<CustomerServiceRequest> fetchRequestById(int requestUid) async {
    final request = await _repository.fetchById(requestUid);
    if (_requests.any((r) => r.uid == request.uid)) {
      _requests = _requests.map((r) => r.uid == request.uid ? request : r).toList();
      notifyListeners();
    }
    return request;
  }

  Future<bool> cancelRequest(CustomerServiceRequest request, {required String reason}) async {
    _cancellingUid = request.uid;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.cancel(request, reason: reason);
      _requests = _requests.map((r) => r.uid == updated.uid ? updated : r).toList();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _cancellingUid = null;
      notifyListeners();
    }
  }

  Future<bool> deleteRequest(int requestUid) async {
    _deletingUid = requestUid;
    _error = null;
    notifyListeners();

    try {
      if (_clientUid != null) {
        await _repository.hide(_clientUid!, requestUid);
      }
      _requests = _requests.where((r) => r.uid != requestUid).toList();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _deletingUid = null;
      notifyListeners();
    }
  }
}
