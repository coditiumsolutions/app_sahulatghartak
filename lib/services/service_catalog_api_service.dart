import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/service_catalog.dart';
import '../utils/constants.dart';

class ServiceCatalogApiService {
  Future<List<ServiceCatalog>> fetchServices() async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/services'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load services (status ${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ServiceCatalog.fromJson(json as Map<String, dynamic>)).toList();
  }
}
