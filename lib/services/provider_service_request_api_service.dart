import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider/service_request.dart';
import '../utils/constants.dart';

class ProviderServiceRequestApiService {
  Future<List<ServiceRequest>> fetchByProvider(int providerId) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/providers/$providerId/service-requests'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load service requests (status ${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ServiceRequest.fromJson(item as Map<String, dynamic>)).toList();
  }
}
