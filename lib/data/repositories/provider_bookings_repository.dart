import '../../models/provider/service_booking.dart';
import '../../services/rejected_bookings_store.dart';
import '../../services/service_booking_api_service.dart';

/// Owns the provider-bookings data source: merges the API's list (which never
/// returns "Rejected" bookings — staff-only per the API contract) with the
/// on-device `RejectedBookingsStore`, and persists a rejected booking as a
/// side effect of `respond(accept: false)`. `ProviderBookingsProvider` should
/// hold only UI state (loading/error/selection flags, the derived
/// unviewed-rejected badge count) and call through to this class rather than
/// talking to the API/store directly.
class ProviderBookingsRepository {
  ProviderBookingsRepository({ServiceBookingApiService? apiService, RejectedBookingsStore? rejectedStore})
      : _apiService = apiService ?? ServiceBookingApiService(),
        _rejectedStore = rejectedStore ?? RejectedBookingsStore();

  final ServiceBookingApiService _apiService;
  final RejectedBookingsStore _rejectedStore;

  Future<List<ServiceBooking>> fetchByProvider(int providerUid) async {
    final fetched = await _apiService.fetchByProvider(providerUid);
    final rejected = await _rejectedStore.load(providerUid);
    return [...fetched, ...rejected];
  }

  Future<int> loadRejectedSeenCount(int providerUid) => _rejectedStore.loadSeenCount(providerUid);

  Future<void> saveRejectedSeenCount(int providerUid, int count) => _rejectedStore.saveSeenCount(providerUid, count);

  Future<ServiceBooking> fetchById(int bookingUid, {int? providerUid}) {
    return _apiService.fetchById(bookingUid, providerUid: providerUid);
  }

  Future<ServiceBooking> respond({required ServiceBooking booking, required bool accept, String? reason}) async {
    final updated = await _apiService.respond(
      bookingUid: booking.uid,
      providerUid: booking.providerUid,
      accept: accept,
      reason: reason,
    );
    if (!accept && updated.isRejected) {
      await _rejectedStore.add(booking.providerUid, updated);
    }
    return updated;
  }

  Future<ServiceBooking> startJob(ServiceBooking booking) {
    return _apiService.startJob(bookingUid: booking.uid, providerUid: booking.providerUid);
  }

  Future<ServiceBooking> verifyCompletion(
    ServiceBooking booking, {
    required String passcode,
    required double actualAmountPaid,
    String? paymentMode,
  }) {
    return _apiService.verifyCompletion(
      bookingUid: booking.uid,
      providerUid: booking.providerUid,
      passcode: passcode,
      actualAmountPaid: actualAmountPaid,
      paymentMode: paymentMode,
    );
  }

  Future<ServiceBooking> updateStatus(ServiceBooking booking, String status, {required double customerPaid, String? reason}) {
    return _apiService.updateBooking(
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
  }
}
