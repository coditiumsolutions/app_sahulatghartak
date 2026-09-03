// Coverage for the merge logic that used to live inline inside
// ProviderBookingsProvider.loadBookings() — the API's list (which never
// includes "Rejected" bookings, staff-only per the API contract) merged with
// the on-device rejected-bookings store, plus the seen-count round-trip used
// to badge newly-rejected bookings. Previously untestable without hitting the
// real http-based API service; the repository extraction (architecture-audit.md
// §6 Task 3) makes both seams injectable via fakes.
import 'package:flutter_test/flutter_test.dart';

import 'package:sahulat_ghar_tak/data/repositories/provider_bookings_repository.dart';
import 'package:sahulat_ghar_tak/models/provider/service_booking.dart';
import 'package:sahulat_ghar_tak/services/rejected_bookings_store.dart';
import 'package:sahulat_ghar_tak/services/service_booking_api_service.dart';

ServiceBooking _booking(int uid, {String status = 'Accepted'}) {
  return ServiceBooking(
    uid: uid,
    requestUid: uid,
    requestTitle: 'Title',
    clientUid: 1,
    clientName: 'Client',
    providerUid: 5,
    providerName: 'Provider',
    serviceDetail: 'Detail',
    estimatedAmount: 100,
    visitCharges: 0,
    additionalCharges: 0,
    deductions: 0,
    finalAmount: 100,
    customerPaid: 0,
    paymentMode: 'Cash',
    customerRemaining: 100,
    commissionType: 'Percentage',
    commissionValue: 10,
    commissionAmount: 10,
    providerEarning: 90,
    status: status,
    createdOn: DateTime(2026, 9, 3),
  );
}

class _FakeApiService extends ServiceBookingApiService {
  _FakeApiService(this.bookings);
  final List<ServiceBooking> bookings;

  @override
  Future<List<ServiceBooking>> fetchByProvider(int providerUid) async => bookings;

  final List<Map<String, Object?>> respondCalls = [];

  @override
  Future<ServiceBooking> respond({required int bookingUid, required int providerUid, required bool accept, String? reason}) async {
    respondCalls.add({'bookingUid': bookingUid, 'accept': accept});
    return _booking(bookingUid, status: accept ? 'Accepted' : 'Rejected');
  }
}

class _FakeRejectedStore extends RejectedBookingsStore {
  _FakeRejectedStore(this.rejected, {int seenCount = 0}) : _seenCount = seenCount;
  final List<ServiceBooking> rejected;
  int _seenCount;

  final List<ServiceBooking> addCalls = [];

  @override
  Future<List<ServiceBooking>> load(int providerUid) async => rejected;

  @override
  Future<void> add(int providerUid, ServiceBooking booking) async => addCalls.add(booking);

  @override
  Future<int> loadSeenCount(int providerUid) async => _seenCount;

  @override
  Future<void> saveSeenCount(int providerUid, int count) async => _seenCount = count;
}

void main() {
  test('fetchByProvider appends the on-device rejected bookings to the API list', () async {
    final api = _FakeApiService([_booking(1), _booking(2)]);
    final rejectedStore = _FakeRejectedStore([_booking(3, status: 'Rejected')]);
    final repo = ProviderBookingsRepository(apiService: api, rejectedStore: rejectedStore);

    final bookings = await repo.fetchByProvider(5);

    expect(bookings.map((b) => b.uid), [1, 2, 3]);
  });

  test('respond(accept: false) persists the rejected booking to the store', () async {
    final api = _FakeApiService([]);
    final rejectedStore = _FakeRejectedStore([]);
    final repo = ProviderBookingsRepository(apiService: api, rejectedStore: rejectedStore);

    await repo.respond(booking: _booking(9), accept: false);

    expect(rejectedStore.addCalls.map((b) => b.uid), [9]);
  });

  test('respond(accept: true) does not touch the rejected store', () async {
    final api = _FakeApiService([]);
    final rejectedStore = _FakeRejectedStore([]);
    final repo = ProviderBookingsRepository(apiService: api, rejectedStore: rejectedStore);

    await repo.respond(booking: _booking(9), accept: true);

    expect(rejectedStore.addCalls, isEmpty);
  });

  test('rejected seen-count round-trips through the store', () async {
    final rejectedStore = _FakeRejectedStore([], seenCount: 2);
    final repo = ProviderBookingsRepository(apiService: _FakeApiService([]), rejectedStore: rejectedStore);

    expect(await repo.loadRejectedSeenCount(5), 2);

    await repo.saveRejectedSeenCount(5, 4);

    expect(await repo.loadRejectedSeenCount(5), 4);
  });
}
