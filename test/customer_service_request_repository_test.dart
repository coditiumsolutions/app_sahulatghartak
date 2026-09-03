// Coverage for the merge/filter logic that used to live inline inside
// CustomerServiceRequestProvider.loadRequests() — fetched requests filtered
// against the on-device "hidden" set, with each visible request's passcode
// persisted as a side effect. Previously untestable without hitting the real
// http-based API service; the repository extraction (architecture-audit.md
// Phase 1 step 1) makes both seams injectable via fakes.
import 'package:flutter_test/flutter_test.dart';

import 'package:sahulat_ghar_tak/data/repositories/customer_service_request_repository.dart';
import 'package:sahulat_ghar_tak/models/customer_service_request.dart';
import 'package:sahulat_ghar_tak/services/customer_service_request_api_service.dart';
import 'package:sahulat_ghar_tak/services/deleted_requests_store.dart';
import 'package:sahulat_ghar_tak/services/request_passcode_store.dart';

CustomerServiceRequest _request(int uid, {String? passcode}) {
  return CustomerServiceRequest(
    uid: uid,
    clientUid: 1,
    clientName: 'Client',
    categoryUid: 1,
    categoryName: 'Category',
    clientAddressUid: 1,
    addressTitle: 'Home',
    serviceTitle: 'Service',
    serviceDescription: 'Description',
    preferredServiceDate: '2026-09-03',
    preferredServiceTime: '10:00',
    isUrgent: false,
    contactPerson: 'Person',
    contactNo: '0300',
    estimatedBudget: 0,
    status: 'Pending',
    createdOn: DateTime(2026, 9, 3),
    passcode: passcode,
  );
}

class _FakeApiService extends CustomerServiceRequestApiService {
  _FakeApiService(this.requests);
  final List<CustomerServiceRequest> requests;

  @override
  Future<List<CustomerServiceRequest>> fetchByClient(int clientUid) async => requests;

  @override
  Future<CustomerServiceRequest> fetchById(int requestUid) async => requests.firstWhere((r) => r.uid == requestUid);
}

class _FakeDeletedStore extends DeletedRequestsStore {
  _FakeDeletedStore(this.hidden);
  final Set<int> hidden;

  @override
  Future<Set<int>> load(int clientUid) async => hidden;

  final List<int> hideCalls = [];

  @override
  Future<void> hide(int clientUid, int requestUid) async {
    hideCalls.add(requestUid);
  }
}

class _FakePasscodeStore extends RequestPasscodeStore {
  final Map<int, String> saved = {};

  @override
  Future<void> save(int requestUid, String passcode) async {
    saved[requestUid] = passcode;
  }
}

void main() {
  test('fetchByClient filters out requests hidden on-device', () async {
    final api = _FakeApiService([_request(1), _request(2), _request(3)]);
    final deletedStore = _FakeDeletedStore({2});
    final repo = CustomerServiceRequestRepository(apiService: api, deletedStore: deletedStore, passcodeStore: _FakePasscodeStore());

    final visible = await repo.fetchByClient(1);

    expect(visible.map((r) => r.uid), [1, 3]);
  });

  test('fetchByClient persists the passcode of every visible request', () async {
    final api = _FakeApiService([_request(1, passcode: 'AAA'), _request(2, passcode: 'BBB')]);
    final passcodeStore = _FakePasscodeStore();
    final repo = CustomerServiceRequestRepository(apiService: api, deletedStore: _FakeDeletedStore({}), passcodeStore: passcodeStore);

    await repo.fetchByClient(1);

    expect(passcodeStore.saved, {1: 'AAA', 2: 'BBB'});
  });

  test('fetchByClient does not persist a passcode for a hidden request', () async {
    final api = _FakeApiService([_request(1, passcode: 'AAA'), _request(2, passcode: 'BBB')]);
    final passcodeStore = _FakePasscodeStore();
    final repo = CustomerServiceRequestRepository(apiService: api, deletedStore: _FakeDeletedStore({2}), passcodeStore: passcodeStore);

    await repo.fetchByClient(1);

    expect(passcodeStore.saved, {1: 'AAA'});
  });

  test('fetchById persists the fetched request\'s passcode', () async {
    final api = _FakeApiService([_request(7, passcode: 'ZZZ')]);
    final passcodeStore = _FakePasscodeStore();
    final repo = CustomerServiceRequestRepository(apiService: api, deletedStore: _FakeDeletedStore({}), passcodeStore: passcodeStore);

    await repo.fetchById(7);

    expect(passcodeStore.saved, {7: 'ZZZ'});
  });

  test('hide() delegates to the deleted-requests store', () async {
    final deletedStore = _FakeDeletedStore({});
    final repo = CustomerServiceRequestRepository(
      apiService: _FakeApiService([]),
      deletedStore: deletedStore,
      passcodeStore: _FakePasscodeStore(),
    );

    await repo.hide(1, 42);

    expect(deletedStore.hideCalls, [42]);
  });
}
