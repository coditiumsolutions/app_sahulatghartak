import 'package:flutter/material.dart';

import '../models/customer_service_request.dart';
import '../services/customer_service_request_api_service.dart';

class CustomerServiceRequestProvider extends ChangeNotifier {
  final CustomerServiceRequestApiService _apiService = CustomerServiceRequestApiService();

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
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _requests = await _apiService.fetchByClient(clientUid);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<CustomerServiceRequest> fetchRequestById(int requestUid) => _apiService.fetchById(requestUid);

  Future<bool> cancelRequest(CustomerServiceRequest request) async {
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
      );
      _requests = _requests.map((r) => r.uid == updated.uid ? updated : r).toList();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
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
      await _apiService.delete(requestUid);
      _requests = _requests.where((r) => r.uid != requestUid).toList();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _deletingUid = null;
      notifyListeners();
    }
  }
}
