import 'package:flutter/material.dart';

import '../models/provider/service_booking.dart';
import '../services/rejected_bookings_store.dart';
import '../services/service_booking_api_service.dart';

class ProviderBookingsProvider extends ChangeNotifier {
  final ServiceBookingApiService _apiService = ServiceBookingApiService();
  final RejectedBookingsStore _rejectedStore = RejectedBookingsStore();

  List<ServiceBooking> _bookings = [];
  List<ServiceBooking> get bookings => _bookings;

  bool _loading = false;
  bool get loading => _loading;

  int? _updatingUid;
  int? get updatingUid => _updatingUid;

  String? _error;
  String? get error => _error;

  int? _providerUid;
  int _rejectedSeenCount = 0;

  int get unviewedRejectedCount {
    final rejectedCount = _bookings.where((b) => b.isRejected).length;
    return (rejectedCount - _rejectedSeenCount).clamp(0, rejectedCount);
  }

  Future<void> markRejectedSeen() async {
    final rejectedCount = _bookings.where((b) => b.isRejected).length;
    if (rejectedCount == _rejectedSeenCount) return;

    _rejectedSeenCount = rejectedCount;
    notifyListeners();
    if (_providerUid != null) {
      await _rejectedStore.saveSeenCount(_providerUid!, rejectedCount);
    }
  }

  Future<void> loadBookings(int providerUid) async {
    _loading = true;
    _error = null;
    _providerUid = providerUid;
    notifyListeners();

    try {
      final fetched = await _apiService.fetchByProvider(providerUid);
      final rejected = await _rejectedStore.load(providerUid);
      _bookings = [...fetched, ...rejected];
      _rejectedSeenCount = await _rejectedStore.loadSeenCount(providerUid);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> respond(ServiceBooking booking, bool accept, {String? reason}) async {
    _updatingUid = booking.uid;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.respond(
        bookingUid: booking.uid,
        providerUid: booking.providerUid,
        accept: accept,
        reason: reason,
      );
      _bookings = _bookings.map((b) => b.uid == updated.uid ? updated : b).toList();
      if (!accept && updated.isRejected) {
        await _rejectedStore.add(booking.providerUid, updated);
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _updatingUid = null;
      notifyListeners();
    }
  }

  Future<bool> verifyCompletion(
    ServiceBooking booking, {
    required String passcode,
    required double actualAmountPaid,
    String? paymentMode,
  }) async {
    _updatingUid = booking.uid;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.verifyCompletion(
        bookingUid: booking.uid,
        providerUid: booking.providerUid,
        passcode: passcode,
        actualAmountPaid: actualAmountPaid,
        paymentMode: paymentMode,
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

  Future<bool> updateStatus(ServiceBooking booking, String status, {required double customerPaid, String? reason}) async {
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
        cancelReason: reason,
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
