import '../../models/provider/provider_wallet.dart';
import '../../services/provider_wallet_api_service.dart';

/// Thin pass-through over `ProviderWalletApiService` — single call, no
/// merging/filtering — exists to give `ProviderWalletProvider` an injectable
/// data-source seam for testing.
class ProviderWalletRepository {
  ProviderWalletRepository({ProviderWalletApiService? apiService}) : _apiService = apiService ?? ProviderWalletApiService();

  final ProviderWalletApiService _apiService;

  Future<ProviderWallet> fetchWallet(int providerUid) => _apiService.fetchWallet(providerUid);
}
