import 'package:flutter/material.dart';

import '../data/repositories/provider_dashboard_repository.dart';
import '../models/provider/availability_status.dart';
import '../models/provider/provider_detail.dart';
import '../models/provider/service_request.dart';
import '../utils/api_error.dart';

class ProviderDashboardProvider extends ChangeNotifier {
  ProviderDashboardProvider({required ProviderDashboardRepository repository}) : _repository = repository;

  final ProviderDashboardRepository _repository;

  ProviderAvailabilityStatus? _availabilityStatus;
  bool get hasAvailabilityRecord => _availabilityStatus != null;
  bool get isOnline => _availabilityStatus?.isOnline ?? false;
  String? get availableFrom => _availabilityStatus?.availableFrom;
  String? get availableTo => _availabilityStatus?.availableTo;
  String? get availableTiming => _availabilityStatus?.availableTiming;

  bool _availabilityLoading = false;
  bool get availabilityLoading => _availabilityLoading;

  String? _availabilityError;
  String? get availabilityError => _availabilityError;

  Future<void> loadAvailabilityStatus(int providerUid) async {
    _availabilityLoading = true;
    _availabilityError = null;
    notifyListeners();

    try {
      _availabilityStatus = await _repository.fetchAvailabilityStatus(providerUid);
    } catch (e) {
      _availabilityError = friendlyErrorMessage(e);
    } finally {
      _availabilityLoading = false;
      notifyListeners();
    }
  }

  /// Sets the provider's Online/Offline status. When going online, [availableFrom]
  /// and [availableTo] (format "HH:mm") are required by the API; when going
  /// offline, any existing timing is cleared server-side. Returns whether the
  /// call succeeded; on failure [availabilityError] carries the message.
  Future<bool> setOnline(int providerUid, bool value, {String? availableFrom, String? availableTo}) async {
    _availabilityLoading = true;
    _availabilityError = null;
    notifyListeners();

    try {
      _availabilityStatus = await _repository.setAvailabilityStatus(
        providerUid: providerUid,
        isOnline: value,
        existing: _availabilityStatus,
        availableFrom: availableFrom,
        availableTo: availableTo,
      );
      return true;
    } catch (e) {
      _availabilityError = friendlyErrorMessage(e);
      return false;
    } finally {
      _availabilityLoading = false;
      notifyListeners();
    }
  }

  List<ServiceRequest> _incomingRequests = [];
  List<ServiceRequest> get incomingRequests => _incomingRequests;

  bool _requestsLoading = false;
  bool get requestsLoading => _requestsLoading;

  String? _requestsError;
  String? get requestsError => _requestsError;

  Future<void> loadIncomingRequests(int providerId) async {
    _requestsLoading = true;
    _requestsError = null;
    notifyListeners();

    try {
      _incomingRequests = await _repository.fetchIncomingRequests(providerId);
    } catch (e) {
      _requestsError = friendlyErrorMessage(e);
    } finally {
      _requestsLoading = false;
      notifyListeners();
    }
  }

  void rejectRequest(int requestId) {
    _incomingRequests = _incomingRequests.where((r) => r.id != requestId).toList();
    notifyListeners();
  }

  ProviderDetailModel? _providerDetail;
  ProviderDetailModel? get providerDetail => _providerDetail;

  bool _profileLoading = false;
  bool get profileLoading => _profileLoading;

  String? _profileError;
  String? get profileError => _profileError;

  Future<void> loadProviderDetail(int providerUid) async {
    _profileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      _providerDetail = await _repository.fetchProviderDetail(providerUid);
    } catch (e) {
      _profileError = friendlyErrorMessage(e);
    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProviderDetail(ProviderDetailModel updated) async {
    _profileError = null;
    try {
      _providerDetail = await _repository.updateProviderDetail(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _profileError = friendlyErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
