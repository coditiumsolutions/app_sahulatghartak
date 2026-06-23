import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_data.dart';
import '../utils/constants.dart';

class AuthApiService {
  Future<AuthData> login(String emailOrPhone, String password) async {
    final json = await _post('login', {
      'emailOrPhone': emailOrPhone,
      'password': password,
    });
    return AuthData.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<String> registerCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String defaultAddress,
  }) async {
    final json = await _post('register-customer', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'defaultAddress': defaultAddress,
    });
    return json['message'] as String? ?? 'Registration successful.';
  }

  Future<String> registerProvider({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required int categoryId,
    required String serviceType,
    required String cnic,
    required int experienceYears,
  }) async {
    final json = await _post('register-provider', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'categoryId': categoryId,
      'serviceType': serviceType,
      'cnic': cnic,
      'experienceYears': experienceYears,
    });
    return json['message'] as String? ?? 'Registration successful.';
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/auth/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (status ${response.statusCode}). Please try again later.');
    }

    final success = json['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      throw Exception(json['message'] as String? ?? 'Request failed (status ${response.statusCode})');
    }
    return json;
  }
}
