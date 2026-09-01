import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/service_title.dart';
import '../utils/constants.dart';

class ServiceTitleApiService {
  Future<List<ServiceTitle>> fetchServiceTitles({required int categoryUid}) async {
    final uri = Uri.parse('$kApiBaseUrl/service-titles').replace(queryParameters: {'categoryUid': '$categoryUid'});

    final response = await http.get(uri).timeout(kApiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load service titles (status ${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ServiceTitle.fromJson(json as Map<String, dynamic>)).toList();
  }
}
