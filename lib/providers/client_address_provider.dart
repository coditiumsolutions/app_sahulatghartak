import 'package:flutter/material.dart';

import '../data/repositories/client_address_repository.dart';
import '../models/client_address.dart';
import '../utils/api_error.dart';

class ClientAddressProvider extends ChangeNotifier {
  ClientAddressProvider({required ClientAddressRepository repository}) : _repository = repository;

  final ClientAddressRepository _repository;

  List<ClientAddress> _addresses = [];
  List<ClientAddress> get addresses => _addresses;

  bool _loading = false;
  bool get loading => _loading;

  bool _saving = false;
  bool get saving => _saving;

  int? _deletingUid;
  int? get deletingUid => _deletingUid;

  String? _error;
  String? get error => _error;

  Future<void> loadAddresses(int clientUid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _repository.fetchByClient(clientUid);
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addAddress({
    required int clientUid,
    required String addressTitle,
    required String fullAddress,
    required String area,
    required String city,
    double latitude = 0,
    double longitude = 0,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _repository.create(
        clientUid: clientUid,
        addressTitle: addressTitle,
        fullAddress: fullAddress,
        area: area,
        city: city,
        latitude: latitude,
        longitude: longitude,
      );
      _addresses = [created, ..._addresses];
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> updateAddress({
    required int addressUid,
    required int clientUid,
    required String addressTitle,
    required String fullAddress,
    required String area,
    required String city,
    double latitude = 0,
    double longitude = 0,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.update(
        addressUid: addressUid,
        clientUid: clientUid,
        addressTitle: addressTitle,
        fullAddress: fullAddress,
        area: area,
        city: city,
        latitude: latitude,
        longitude: longitude,
      );
      _addresses = _addresses.map((a) => a.uid == updated.uid ? updated : a).toList();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAddress(int addressUid) async {
    _deletingUid = addressUid;
    _error = null;
    notifyListeners();

    try {
      await _repository.delete(addressUid);
      _addresses = _addresses.where((a) => a.uid != addressUid).toList();
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
