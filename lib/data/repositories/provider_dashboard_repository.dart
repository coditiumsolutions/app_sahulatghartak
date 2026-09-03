import '../../models/provider/availability_status.dart';
import '../../models/provider/provider_detail.dart';
import '../../models/provider/service_request.dart';
import '../../services/provider_availability_api_service.dart';
import '../../services/provider_profile_api_service.dart';
import '../../services/provider_service_request_api_service.dart';

/// Owns the provider-dashboard data sources: profile detail, availability
/// status, and incoming service requests. Three separate real services
/// (no merging/filtering between them, unlike the customer-requests and
/// bookings repositories) — `ProviderDashboardProvider` should hold only UI
/// state and call through to this class.
class ProviderDashboardRepository {
  ProviderDashboardRepository({
    ProviderProfileApiService? profileApiService,
    ProviderAvailabilityApiService? availabilityApiService,
    ProviderServiceRequestApiService? serviceRequestApiService,
  })  : _profileApiService = profileApiService ?? ProviderProfileApiService(),
        _availabilityApiService = availabilityApiService ?? ProviderAvailabilityApiService(),
        _serviceRequestApiService = serviceRequestApiService ?? ProviderServiceRequestApiService();

  final ProviderProfileApiService _profileApiService;
  final ProviderAvailabilityApiService _availabilityApiService;
  final ProviderServiceRequestApiService _serviceRequestApiService;

  Future<ProviderDetailModel> fetchProviderDetail(int providerUid) => _profileApiService.fetchDetail(providerUid);

  Future<ProviderDetailModel> updateProviderDetail(ProviderDetailModel updated) => _profileApiService.updateDetail(updated);

  Future<ProviderAvailabilityStatus?> fetchAvailabilityStatus(int providerUid) => _availabilityApiService.fetchStatus(providerUid);

  Future<ProviderAvailabilityStatus> setAvailabilityStatus({
    required int providerUid,
    required bool isOnline,
    required ProviderAvailabilityStatus? existing,
    String? availableFrom,
    String? availableTo,
  }) {
    return existing == null
        ? _availabilityApiService.createStatus(
            providerUid: providerUid,
            isOnline: isOnline,
            availableFrom: availableFrom,
            availableTo: availableTo,
          )
        : _availabilityApiService.updateStatus(
            providerUid: providerUid,
            isOnline: isOnline,
            availableFrom: availableFrom,
            availableTo: availableTo,
          );
  }

  Future<List<ServiceRequest>> fetchIncomingRequests(int providerId) => _serviceRequestApiService.fetchByProvider(providerId);
}
