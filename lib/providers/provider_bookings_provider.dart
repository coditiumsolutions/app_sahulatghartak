import 'package:flutter/material.dart';

import '../models/provider/service_booking.dart';
import '../services/service_booking_api_service.dart';

class ProviderBookingsProvider extends ChangeNotifier {
  final ServiceBookingApiService _apiService = ServiceBookingApiService();

  List<ServiceBooking> _bookings = [];
  List<ServiceBooking> get bookings => _bookings;

  bool _loading = false;
  bool get loading => _loading;

  int? _updatingUid;
  int? get updatingUid => _updatingUid;

  String? _error;
  String? get error => _error;

  Future<void> loadBookings(int providerUid) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await _apiService.fetchByProvider(providerUid);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(ServiceBooking booking, String status, {required double customerPaid}) async {
    _updatingUid = booking.uid;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateBooking(
        bookingUid: booking.uid,
        providerUid: booking.providerUid,
        serviceDetail: booking.serviceDetail,
        estimatedAmount: booking.estimatedAmount,
        visitCharges: booking.visitCharges,
        additionalCharges: booking.additionalCharges,
        deductions: booking.deductions,
        customerPaid: customerPaid,
        paymentMode: booking.paymentMode,
        commissionType: booking.commissionType,
        commissionValue: booking.commissionValue,
        status: status,
      );
      _bookings = _bookings.map((b) => b.uid == updated.uid ? updated : b).toList();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _updatingUid = null;
      notifyListeners();
    }
  }
}
