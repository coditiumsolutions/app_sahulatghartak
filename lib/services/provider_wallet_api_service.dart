import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider/provider_wallet.dart';
import '../utils/constants.dart';

class ProviderWalletApiService {
  Future<ProviderWallet> fetchWallet(int providerUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/providers-wallet/$providerUid'));

    final json = _decode(response, 'Failed to load wallet');
    return ProviderWallet.fromJson(json['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decode(http.Response response, String errorPrefix) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('$errorPrefix (status ${response.statusCode})');
    }

    final success = json['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      throw Exception(json['message'] as String? ?? errorPrefix);
    }
    return json;
  }
}
