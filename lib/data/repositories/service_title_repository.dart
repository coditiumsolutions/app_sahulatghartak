import '../../models/service_title.dart';
import '../../services/service_title_api_service.dart';

/// Thin pass-through over `ServiceTitleApiService` — single call, no
/// merging/filtering — exists to give `ServiceTitleProvider` an injectable
/// data-source seam for testing.
class ServiceTitleRepository {
  ServiceTitleRepository({ServiceTitleApiService? apiService}) : _apiService = apiService ?? ServiceTitleApiService();

  final ServiceTitleApiService _apiService;

  Future<List<ServiceTitle>> fetchServiceTitles(int categoryUid) => _apiService.fetchServiceTitles(categoryUid: categoryUid);
}
