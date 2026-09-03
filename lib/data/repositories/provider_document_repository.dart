import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../models/provider/provider_documents.dart';
import '../../services/provider_document_api_service.dart';
import '../../utils/constants.dart';

/// Owns the provider-document data source: fetching/uploading via
/// `ProviderDocumentApiService`, resolving a stored relative path to a full
/// URL, and re-downloading an already-uploaded image to a local temp file
/// when the upload endpoint needs all three slots resent but the caller only
/// picked a replacement for one. `ProviderDocumentProvider` should keep only
/// UI state (the `ImagePicker`, freshly-picked `File`s, loading/progress
/// flags) and call through to this class.
class ProviderDocumentRepository {
  ProviderDocumentRepository({ProviderDocumentApiService? apiService}) : _apiService = apiService ?? ProviderDocumentApiService();

  final ProviderDocumentApiService _apiService;

  Future<ProviderDocumentsModel?> fetchDocuments(int providerUid) => _apiService.fetchDocuments(providerUid);

  Future<ProviderDocumentsModel> upload({
    required int providerUid,
    required File profilePhoto,
    required File cnicFront,
    required File cnicBack,
    void Function(double progress)? onProgress,
  }) {
    return _apiService.uploadDocuments(
      providerUid: providerUid,
      profilePhoto: profilePhoto,
      cnicFront: cnicFront,
      cnicBack: cnicBack,
      onProgress: onProgress,
    );
  }

  String? resolveUrl(String? relativePath) => relativePath == null ? null : '$kApiFileBaseUrl/$relativePath';

  /// Downloads the image currently at [remoteUrl] to a local temp file, so it
  /// can be resent alongside a newly picked replacement in another slot.
  Future<File> downloadToTempFile(String remoteUrl) async {
    final response = await http.get(Uri.parse(remoteUrl));
    if (response.statusCode != 200) {
      throw Exception('Could not load the existing image. Please pick it again.');
    }

    final dir = await getTemporaryDirectory();
    final fileName = '${DateTime.now().microsecondsSinceEpoch}_${remoteUrl.split('/').last}';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
