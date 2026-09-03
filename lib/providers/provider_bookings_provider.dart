import 'package:flutter/material.dart';

import '../data/repositories/provider_bookings_repository.dart';
import '../models/provider/service_booking.dart';
import '../utils/api_error.dart';

class ProviderBookingsProvider extends ChangeNotifier {
  ProviderBookingsProvider({required ProviderBookingsRepository repository}) : _repository = repository;

  final ProviderBookingsRepository _repository;

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
      await _repository.saveRejectedSeenCount(_providerUid!, rejectedCount);
    }
  }

  Future<void> loadBookings(int providerUid) async {
    _loading = true;
    _error = null;
    _providerUid = providerUid;
    notifyListeners();

    try {
      _bookings = await _repository.fetchByProvider(providerUid);
      _rejectedSeenCount = await _repository.loadRejectedSeenCount(providerUid);
    } catch (e) {
      _error = friendlyErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  ServiceBooking? _selectedBooking;
  ServiceBooking? get selectedBooking => _selectedBooking;

  bool _detailLoading = false;
  bool get detailLoading => _detailLoading;

  String? _detailError;
  String? get detailError => _detailError;

  /// Detail-screen selection state (architecture-audit.md §6 Task 7): fetches
  /// [bookingUid], exposes it via [selectedBooking] while also merging it
  /// into [bookings], so a future detail-screen split (Phase 3) can render
  /// from this ViewModel alone instead of seeding itself from a
  /// navigation-argument copy or keeping its own local `State`. Call
  /// [clearSelection] from the screen's `dispose()`.
  Future<void> selectBooking(int bookingUid, int providerUid) async {
    _detailLoading = true;
    _detailError = null;
    notifyListeners();

    try {
      _selectedBooking = await fetchBookingById(bookingUid, providerUid);
    } catch (e) {
      _detailError = friendlyErrorMessage(e);
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedBooking = null;
    _detailLoading = false;
    _detailError = null;
  }

  /// Fetches a single booking fresh from the API and merges it into
  /// [bookings] (if present there), so the list and any other open screen
  /// watching this provider stay in sync — mirrors
  /// `CustomerServiceRequestProvider.fetchRequestById`'s fix for the same
  /// "detail page refreshed, list still stale" gap.
  Future<ServiceBooking> fetchBookingById(int bookingUid, int providerUid) async {
    final booking = await _repository.fetchById(bookingUid, providerUid: providerUid);
    if (_bookings.any((b) => b.uid == booking.uid)) {
      _bookings = _bookings.map((b) => b.uid == booking.uid ? booking : b).toList();
      notifyListeners();
    }
    return booking;
  }

  Future<bool> respond(ServiceBooking booking, bool accept, {String? reason}) async {
    _updatingUid = booking.uid;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.respond(booking: booking, accept: accept, reason: reason);
      _bookings = _bookings.map((b) => b.uid == updated.uid ? updated : b).toList();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _updatingUid = null;
      notifyListeners();
    }
  }

  Future<bool> startJob(ServiceBooking booking) async {
    _updatingUid = booking.uid;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.startJob(booking);
      _bookings = _bookings.map((b) => b.uid == updated.uid ? updated : b).toList();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
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
      final updated = await _repository.verifyCompletion(
        booking,
        passcode: passcode,
        actualAmountPaid: actualAmountPaid,
        paymentMode: paymentMode,
      );
      _bookings = _bookings.map((b) => b.uid == updated.uid ? updated : b).toList();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
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
      final updated = await _repository.updateStatus(booking, status, customerPaid: customerPaid, reason: reason);
      _bookings = _bookings.map((b) => b.uid == updated.uid ? updated : b).toList();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _updatingUid = null;
      notifyListeners();
    }
  }
}
