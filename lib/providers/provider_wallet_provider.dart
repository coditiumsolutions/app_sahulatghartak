import 'package:flutter/material.dart';

import '../models/provider/provider_wallet.dart';
import '../services/provider_wallet_api_service.dart';
import '../utils/api_error.dart';

class ProviderWalletProvider extends ChangeNotifier {
  final ProviderWalletApiService _apiService = ProviderWalletApiService();

  ProviderWallet? _wallet;
  ProviderWallet? get wallet => _wallet;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadWallet(int providerUid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await _apiService.fetchWallet(providerUid);
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
