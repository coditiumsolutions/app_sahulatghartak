import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider_profile_model.dart';
import '../models/provider/provider_detail.dart';
import '../utils/constants.dart';

class ProviderProfileApiService {
  Future<ProviderDetailModel> fetchDetail(int providerUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/providers-detail/$providerUid')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load provider detail');
    return ProviderDetailModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ProviderDetailModel> updateDetail(ProviderDetailModel updated) async {
    final response = await http
        .put(
          Uri.parse('$kApiBaseUrl/providers-detail/${updated.uid}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'providerUid': updated.uid,
            'fullName': updated.fullName,
            'cnic': updated.cnic,
            'gender': updated.gender,
            'experienceYears': updated.experienceYears,
            'description': updated.description,
            'categoryId': updated.categoryId,
          }),
        )
        .timeout(kApiTimeout);

    final json = _decode(response, 'Failed to update provider detail');
    return ProviderDetailModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<ProviderProfileModel>> fetchByCategory(int categoryId) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/provider-profiles?categoryId=$categoryId')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load service providers');
    final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
    return data.map((item) => ProviderProfileModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ProviderProfileModel> fetchById(int userId) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/provider-profiles/$userId')).timeout(kApiTimeout);

    final json = _decode(response, 'Failed to load provider profile');
    return ProviderProfileModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Map<String, dynamic> _decode(http.Response response, String errorPrefix) {
    if (response.statusCode != 200) {
      throw Exception('$errorPrefix (status ${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final success = json['success'] as bool? ?? true;
    if (!success) {
      throw Exception(json['message'] as String? ?? errorPrefix);
    }
    return json;
  }
}
