import '../../models/customer_service_request.dart';
import '../../services/customer_service_request_api_service.dart';
import '../../services/deleted_requests_store.dart';
import '../../services/request_passcode_store.dart';

/// Owns the customer service-request data source: merges the API's list
/// with the on-device "deleted" (hidden) set, and persists each request's
/// passcode as a side effect of fetching. `CustomerServiceRequestProvider`
/// should hold only UI state (loading/error/selection flags) and call
/// through to this class rather than talking to the API/stores directly.
class CustomerServiceRequestRepository {
  CustomerServiceRequestRepository({
    CustomerServiceRequestApiService? apiService,
    RequestPasscodeStore? passcodeStore,
    DeletedRequestsStore? deletedStore,
  })  : _apiService = apiService ?? CustomerServiceRequestApiService(),
        _passcodeStore = passcodeStore ?? RequestPasscodeStore(),
        _deletedStore = deletedStore ?? DeletedRequestsStore();

  final CustomerServiceRequestApiService _apiService;
  final RequestPasscodeStore _passcodeStore;
  final DeletedRequestsStore _deletedStore;

  Future<List<CustomerServiceRequest>> fetchByClient(int clientUid) async {
    final fetched = await _apiService.fetchByClient(clientUid);
    final hidden = await _deletedStore.load(clientUid);
    final visible = fetched.where((r) => !hidden.contains(r.uid)).toList();
    for (final request in visible) {
      _persistPasscode(request);
    }
    return visible;
  }

  void _persistPasscode(CustomerServiceRequest request) {
    if (request.passcode != null) {
      _passcodeStore.save(request.uid, request.passcode!);
    }
  }

  /// Falls back to the on-device copy saved the last time this request's
  /// passcode was received from the API — keeps "Show Passcode" working
  /// even if the request is later refetched without a live connection.
  Future<String?> getStoredPasscode(int requestUid) => _passcodeStore.load(requestUid);

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
  }) {
    return _apiService.create(
      clientUid: clientUid,
      categoryUid: categoryUid,
      clientAddressUid: clientAddressUid,
      serviceTitle: serviceTitle,
      serviceDescription: serviceDescription,
      preferredServiceDate: preferredServiceDate,
      preferredServiceTime: preferredServiceTime,
      isUrgent: isUrgent,
      contactPerson: contactPerson,
      contactNo: contactNo,
      estimatedBudget: estimatedBudget,
      remarks: remarks,
    );
  }

  Future<CustomerServiceRequest> fetchById(int requestUid) async {
    final request = await _apiService.fetchById(requestUid);
    _persistPasscode(request);
    return request;
  }

  Future<CustomerServiceRequest> cancel(CustomerServiceRequest request, {required String reason}) {
    return _apiService.updateStatus(
      requestUid: request.uid,
      categoryUid: request.categoryUid,
      clientAddressUid: request.clientAddressUid,
      serviceTitle: request.serviceTitle,
      serviceDescription: request.serviceDescription,
      preferredServiceDate: request.preferredServiceDate,
      preferredServiceTime: request.preferredServiceTime,
      isUrgent: request.isUrgent,
      contactPerson: request.contactPerson,
      contactNo: request.contactNo,
      status: 'Cancelled',
      estimatedBudget: request.estimatedBudget,
      remarks: request.remarks,
      cancelReason: reason,
    );
  }

  /// Hides [requestUid] from [clientUid]'s list on-device. Never touches the
  /// backend — the request stays in the database.
  Future<void> hide(int clientUid, int requestUid) => _deletedStore.hide(clientUid, requestUid);
}
