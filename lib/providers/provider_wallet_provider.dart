import 'package:flutter/material.dart';

import '../data/repositories/provider_wallet_repository.dart';
import '../models/provider/provider_wallet.dart';
import '../utils/api_error.dart';

class ProviderWalletProvider extends ChangeNotifier {
  ProviderWalletProvider({required ProviderWalletRepository repository}) : _repository = repository;

  final ProviderWalletRepository _repository;

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
      _wallet = await _repository.fetchWallet(providerUid);
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
