import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../utils/constants.dart';

class CategoryApiService {
  Future<List<Category>> fetchCategories({int? serviceUid}) async {
    final uri = serviceUid == null
        ? Uri.parse('$kApiBaseUrl/service-categories')
        : Uri.parse('$kApiBaseUrl/service-categories').replace(queryParameters: {'serviceUid': '$serviceUid'});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories (status ${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }
}
