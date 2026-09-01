import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider/availability_status.dart';
import '../utils/constants.dart';

class ProviderAvailabilityApiService {
  Future<ProviderAvailabilityStatus?> fetchStatus(int providerUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/provider-avability-status/$providerUid')).timeout(kApiTimeout);
    if (response.statusCode == 404) return null;

    final json = _decode(response, 'Failed to load availability status');
    return ProviderAvailabilityStatus.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ProviderAvailabilityStatus> createStatus({
    required int providerUid,
    required bool isOnline,
    String? availableFrom,
    String? availableTo,
  }) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/provider-avability-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_body(providerUid, isOnline, availableFrom, availableTo)),
    ).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to save availability status');
    return ProviderAvailabilityStatus.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ProviderAvailabilityStatus> updateStatus({
    required int providerUid,
    required bool isOnline,
    String? availableFrom,
    String? availableTo,
  }) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/provider-avability-status/$providerUid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_body(providerUid, isOnline, availableFrom, availableTo)),
    ).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to update availability status');
    return ProviderAvailabilityStatus.fromJson(json['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _body(int providerUid, bool isOnline, String? availableFrom, String? availableTo) {
    final body = <String, dynamic>{'providerUid': providerUid, 'isOnline': isOnline};
    if (isOnline) {
      body['availableFrom'] = availableFrom;
      body['availableTo'] = availableTo;
    }
    return body;
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
