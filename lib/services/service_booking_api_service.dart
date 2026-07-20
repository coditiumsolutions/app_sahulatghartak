import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider/service_booking.dart';
import '../utils/constants.dart';

class ServiceBookingApiService {
  Future<List<ServiceBooking>> fetchByProvider(int providerUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/service-bookings?providerUid=$providerUid'));

    final json = _decode(response, 'Failed to load bookings');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ServiceBooking.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ServiceBooking> updateBooking({
    required int bookingUid,
    required int providerUid,
    required String serviceDetail,
    required double estimatedAmount,
    required double visitCharges,
    required double additionalCharges,
    required double deductions,
    required double customerPaid,
    required String paymentMode,
    required String commissionType,
    required double commissionValue,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$kApiBaseUrl/service-bookings/$bookingUid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bookingUid': bookingUid,
        'providerUid': providerUid,
        'serviceDetail': serviceDetail,
        'estimatedAmount': estimatedAmount,
        'visitCharges': visitCharges,
        'additionalCharges': additionalCharges,
        'deductions': deductions,
        'customerPaid': customerPaid,
        'paymentMode': paymentMode,
        'commissionType': commissionType,
        'commissionValue': commissionValue,
        'status': status,
      }),
    );

    final json = _decode(response, 'Failed to update booking');
    return ServiceBooking.fromJson(json['data'] as Map<String, dynamic>);
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
