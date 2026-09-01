import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/customer_service_request.dart';
import '../utils/constants.dart';

class CustomerServiceRequestApiService {
  Future<List<CustomerServiceRequest>> fetchByClient(int clientUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/customer-service-requests?clientUid=$clientUid')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load service requests');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => CustomerServiceRequest.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CustomerServiceRequest> fetchById(int requestUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/customer-service-requests/$requestUid')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load service request');
    return CustomerServiceRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<CustomerServiceRequest> create({
    required int clientUid,
    required int categoryUid,
    required int clientAddressUid,
    required String serviceTitle,
    required String serviceDescription,
    required String preferredServiceDate,
    required String preferredServiceTime,
    required bool isUrgent,
    required String contactPerson,
    required String contactNo,
    double? estimatedBudget,
    String? remarks,
  }) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/customer-service-requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clientUid': clientUid,
        'categoryUid': categoryUid,
        'clientAddressUid': clientAddressUid,
        'serviceTitle': serviceTitle,
        'serviceDescription': serviceDescription,
        'preferredServiceDate': preferredServiceDate,
        'preferredServiceTime': preferredServiceTime,
        'isUrgent': isUrgent,
        'contactPerson': contactPerson,
        'contactNo': contactNo,
        'estimatedBudget': estimatedBudget,
        'remarks': remarks,
      }),
    ).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to create service request');
    return CustomerServiceRequest.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<CustomerServiceRequest> updateStatus({
    required int requestUid,
    required int categoryUid,
    required int clientAddressUid,
    required String serviceTitle,
    required String serviceDescription,
    required String preferredServiceDate,
    required String preferredServiceTime,
    required bool isUrgent,
    required String contactPerson,
    required String contactNo,
    required String status,
    double? estimatedBudget,
    String? remarks,
    String? cancelReason,
  }) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/customer-service-requests/$requestUid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestUid': requestUid,
        'categoryUid': categoryUid,
        'clientAddressUid': clientAddressUid,
        'serviceTitle': serviceTitle,
        'serviceDescription': serviceDescription,
        'preferredServiceDate': preferredServiceDate,
        'preferredServiceTime': preferredServiceTime,
        'isUrgent': isUrgent,
        'contactPerson': contactPerson,
        'contactNo': contactNo,
        'estimatedBudget': estimatedBudget,
        'status': status,
        'remarks': remarks,
        'cancelReason': cancelReason,
      }),
    ).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to update service request');
    return CustomerServiceRequest.fromJson(json['data'] as Map<String, dynamic>);
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
