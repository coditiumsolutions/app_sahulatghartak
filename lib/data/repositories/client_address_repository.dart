import '../../models/client_address.dart';
import '../../services/client_address_api_service.dart';

/// Thin pass-through over `ClientAddressApiService` — plain CRUD, no
/// merging/filtering, so this repository exists purely to give
/// `ClientAddressProvider` an injectable data-source seam for testing.
class ClientAddressRepository {
  ClientAddressRepository({ClientAddressApiService? apiService}) : _apiService = apiService ?? ClientAddressApiService();

  final ClientAddressApiService _apiService;

  Future<List<ClientAddress>> fetchByClient(int clientUid) => _apiService.fetchByClient(clientUid);

  Future<ClientAddress> create({
    required int clientUid,
    required String addressTitle,
    required String fullAddress,
    required String area,
    required String city,
    double latitude = 0,
    double longitude = 0,
  }) {
    return _apiService.create(
      clientUid: clientUid,
      addressTitle: addressTitle,
      fullAddress: fullAddress,
      area: area,
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<ClientAddress> update({
    required int addressUid,
    required int clientUid,
    required String addressTitle,
    required String fullAddress,
    required String area,
    required String city,
    double latitude = 0,
    double longitude = 0,
  }) {
    return _apiService.update(
      addressUid: addressUid,
      clientUid: clientUid,
      addressTitle: addressTitle,
      fullAddress: fullAddress,
      area: area,
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> delete(int addressUid) => _apiService.delete(addressUid);
}
