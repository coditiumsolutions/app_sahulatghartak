import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client_detail.dart';
import '../utils/constants.dart';

class ClientProfileApiService {
  Future<ClientDetailModel> fetchDetail(int clientUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/clients-detail/$clientUid')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load profile');
    return ClientDetailModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ClientDetailModel> updateDetail({
    required int clientUid,
    required String fullName,
    required String cnic,
    required String gender,
  }) async {
    final response = await http
        .put(
          Uri.parse('$kApiBaseUrl/clients-detail/$clientUid'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'clientUid': clientUid,
            'fullName': fullName,
            'cnic': cnic,
            'gender': gender,
          }),
        )
        .timeout(kApiTimeout);

    final json = _decode(response, 'Failed to update profile');
    return ClientDetailModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decode(http.Response response, String errorPrefix) {
    if (response.statusCode != 200) {
      throw Exception('$errorPrefix (status ${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final success = json['success'] as bool? ?? true;
    if (!success) {
      throw Exception(json['message'] as String? ?? errorPrefix);
    }
    return json;
  }
}
