import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_data.dart';
import '../models/otp_data.dart';
import '../utils/constants.dart';

class AuthApiService {
  Future<AuthData> login(String mobileNo, String password) async {
    final json = await _post('login', {
      'mobileNo': mobileNo,
      'password': password,
    });
    return AuthData.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<String> registerCustomer({
    required String fullName,
    required String mobileNo,
    required String password,
    required String confirmPassword,
    required String cnic,
    required String gender,
  }) async {
    final json = await _post('register-client', {
      'mobileNo': mobileNo,
      'password': password,
      'confirmPassword': confirmPassword,
      'fullName': fullName,
      'cnic': cnic,
      'gender': gender,
    });
    return json['message'] as String? ?? 'Registration successful.';
  }

  Future<int> registerProvider({
    required String fullName,
    required String mobileNo,
    required String password,
    required String cnic,
    required String gender,
    required int experienceYears,
    required String description,
    required int categoryId,
    required String categoryName,
  }) async {
    final json = await _post('register-provider', {
      'mobileNo': mobileNo,
      'password': password,
      'fullName': fullName,
      'cnic': cnic,
      'gender': gender,
      'experienceYears': experienceYears,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
    });
    final data = json['data'] as Map<String, dynamic>?;
    return (data?['providerUid'] as int?) ?? (data?['profileId'] as int?) ?? 0;
  }

  Future<OtpData> sendOtp(String mobileNo, {String otpType = 'Registration'}) async {
    final json = await _post('send-otp', {'mobileNo': mobileNo, 'otpType': otpType});
    return OtpData.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<OtpData> resendOtp(String mobileNo, {String otpType = 'Registration'}) async {
    final json = await _post('resend-otp', {'mobileNo': mobileNo, 'otpType': otpType});
    return OtpData.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> verifyOtp(String mobileNo, String otp) async {
    await _post('verify-otp', {'mobileNo': mobileNo, 'otp': otp});
  }

  Future<void> deleteAccount(String mobileNo, String password) async {
    await _post('delete-account', {'mobileNo': mobileNo, 'password': password});
  }

  Future<void> resetPassword(String mobileNo, String otp, String newPassword, String confirmNewPassword) async {
    await _post('reset-password', {
      'mobileNo': mobileNo,
      'otp': otp,
      'newPassword': newPassword,
      'confirmNewPassword': confirmNewPassword,
    });
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/auth/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(kApiTimeout);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (status ${response.statusCode}). Please try again later.');
    }

    final success = json['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      throw Exception(_extractErrorMessage(json, response.statusCode));
    }
    return json;
  }

  String _extractErrorMessage(Map<String, dynamic> json, int statusCode) {
    if (json['message'] is String) return json['message'] as String;

    final errors = json['errors'];
    if (errors is Map) {
      final messages = errors.values
          .expand((v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }

    if (json['title'] is String) return json['title'] as String;

    return 'Request failed (status $statusCode)';
  }
}
