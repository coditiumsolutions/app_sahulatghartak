import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client_address.dart';
import '../utils/constants.dart';

class ClientAddressApiService {
  Future<List<ClientAddress>> fetchByClient(int clientUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/client-addresses?clientUid=$clientUid'));

    final json = _decode(response, 'Failed to load addresses');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ClientAddress.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ClientAddress> create({
    required int clientUid,
    required String addressTitle,
    required String fullAddress,
    required String area,
    required String city,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/client-addresses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clientUid': clientUid,
        'addressTitle': addressTitle,
        'fullAddress': fullAddress,
        'area': area,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final json = _decode(response, 'Failed to add address');
    return ClientAddress.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ClientAddress> update({
    required int addressUid,
    required int clientUid,
    required String addressTitle,
    required String fullAddress,
    required String area,
    required String city,
    double latitude = 0,
    double longitude = 0,
  }) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/client-addresses/$addressUid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'addressUid': addressUid,
        'clientUid': clientUid,
        'addressTitle': addressTitle,
        'fullAddress': fullAddress,
        'area': area,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final json = _decode(response, 'Failed to update address');
    return ClientAddress.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int addressUid) async {
    final response = await http.delete(Uri.parse('$kApiBaseUrl/client-addresses/$addressUid'));
    _decode(response, 'Failed to delete address');
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
