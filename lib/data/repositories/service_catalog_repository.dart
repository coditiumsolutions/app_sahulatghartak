import '../../models/service_catalog.dart';
import '../../services/service_catalog_api_service.dart';

/// Thin pass-through over `ServiceCatalogApiService` — single call, no
/// merging/filtering — exists to give `ServiceCatalogProvider` an injectable
/// data-source seam for testing.
class ServiceCatalogRepository {
  ServiceCatalogRepository({ServiceCatalogApiService? apiService}) : _apiService = apiService ?? ServiceCatalogApiService();

  final ServiceCatalogApiService _apiService;

  Future<List<ServiceCatalog>> fetchServices() async {
    final services = await _apiService.fetchServices();
    services.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return services;
  }
}
