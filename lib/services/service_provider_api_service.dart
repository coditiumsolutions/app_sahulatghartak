import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/service_provider_model.dart';
import '../utils/constants.dart';

class ServiceProviderApiService {
  Future<List<ServiceProviderModel>> fetchByCategory(int categoryId) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/service-providers?categoryId=$categoryId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load service providers (status ${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ServiceProviderModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
