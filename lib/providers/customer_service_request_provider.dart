import 'package:flutter/material.dart';

import '../models/customer_service_request.dart';
import '../services/customer_service_request_api_service.dart';
import '../services/deleted_requests_store.dart';
import '../services/request_passcode_store.dart';
import '../utils/api_error.dart';

class CustomerServiceRequestProvider extends ChangeNotifier {
  final CustomerServiceRequestApiService _apiService = CustomerServiceRequestApiService();
  final RequestPasscodeStore _passcodeStore = RequestPasscodeStore();
  final DeletedRequestsStore _deletedStore = DeletedRequestsStore();

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
      final fetched = await _apiService.fetchByClient(clientUid);
      final hidden = await _deletedStore.load(clientUid);
      _requests = fetched.where((r) => !hidden.contains(r.uid)).toList();
      for (final request in _requests) {
        _persistPasscode(request);
      }
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _persistPasscode(CustomerServiceRequest request) {
    if (request.passcode != null) {
      _passcodeStore.save(request.uid, request.passcode!);
    }
  }

  /// Falls back to the on-device copy saved the last time this request's
  /// passcode was received from the API — keeps "Show Passcode" working
  /// even if the request is later refetched without a live connection.
  Future<String?> getStoredPasscode(int requestUid) => _passcodeStore.load(requestUid);

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
      final created = await _apiService.create(
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

  /// Fetches a single request fresh from the API and merges it into
  /// [requests] (if present there), so any screen watching this provider —
  /// not just the caller — sees the update immediately. Without this, a
  /// detail screen's own pull-to-refresh would only ever update its local
  /// copy, leaving the main list showing stale data until its own refresh.
  Future<CustomerServiceRequest> fetchRequestById(int requestUid) async {
    final request = await _apiService.fetchById(requestUid);
    _persistPasscode(request);
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
      final updated = await _apiService.updateStatus(
        requestUid: request.uid,
        categoryUid: request.categoryUid,
        clientAddressUid: request.clientAddressUid,
        serviceTitle: request.serviceTitle,
        serviceDescription: request.serviceDescription,
        preferredServiceDate: request.preferredServiceDate,
        preferredServiceTime: request.preferredServiceTime,
        isUrgent: request.isUrgent,
        contactPerson: request.contactPerson,
        contactNo: request.contactNo,
        status: 'Cancelled',
        estimatedBudget: request.estimatedBudget,
        remarks: request.remarks,
        cancelReason: reason,
      );
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
        await _deletedStore.hide(_clientUid!, requestUid);
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
