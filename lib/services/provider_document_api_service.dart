import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/provider/provider_documents.dart';
import '../utils/constants.dart';

class ProviderDocumentApiService {
  /// Fetches the provider's currently uploaded documents, if any.
  /// Returns null when the provider hasn't uploaded documents yet (404).
  Future<ProviderDocumentsModel?> fetchDocuments(int providerUid) async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/provider/$providerUid/documents')).timeout(kApiTimeout);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (status ${response.statusCode}). Please try again later.');
    }

    final success = json['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      if (response.statusCode == 404) return null;
      throw Exception(json['message'] as String? ?? 'Failed to load documents (status ${response.statusCode}).');
    }

    return ProviderDocumentsModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Uploads the provider's profile photo and CNIC images as multipart/form-data.
  ///
  /// [onProgress] is called with a value between 0.0 and 1.0 as the request body
  /// is streamed to the server (upload progress, not server processing time).
  Future<ProviderDocumentsModel> uploadDocuments({
    required int providerUid,
    required File profilePhoto,
    required File cnicFront,
    required File cnicBack,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/provider/upload-documents');
    final request = http.MultipartRequest('POST', uri)
      ..fields['ProviderUID'] = providerUid.toString()
      ..files.add(await _imagePart('ProfilePhoto', profilePhoto))
      ..files.add(await _imagePart('CNICFront', cnicFront))
      ..files.add(await _imagePart('CNICBack', cnicBack));

    final streamedResponse = await _sendWithProgress(request, onProgress);
    final response = await http.Response.fromStream(streamedResponse);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (status ${response.statusCode}). Please try again later.');
    }

    final success = json['success'] as bool? ?? (response.statusCode >= 200 && response.statusCode < 300);
    if (!success) {
      throw Exception(json['message'] as String? ?? 'Failed to upload documents (status ${response.statusCode}).');
    }

    return ProviderDocumentsModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<http.MultipartFile> _imagePart(String field, File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final subtype = ext == 'png' ? 'png' : 'jpeg';
    return http.MultipartFile.fromPath(field, file.path, contentType: MediaType('image', subtype));
  }

  /// Wraps [http.MultipartRequest.send] to report upload progress, since the
  /// `http` package does not expose this natively.
  Future<http.StreamedResponse> _sendWithProgress(
    http.MultipartRequest request,
    void Function(double progress)? onProgress,
  ) async {
    if (onProgress == null) return request.send().timeout(kApiUploadTimeout);

    final total = request.contentLength;
    var bytesSent = 0;

    final byteStream = request.finalize();
    final progressController = StreamController<List<int>>();
    byteStream.listen(
      (chunk) {
        bytesSent += chunk.length;
        if (total > 0) onProgress(bytesSent / total);
        progressController.add(chunk);
      },
      onDone: progressController.close,
      onError: progressController.addError,
      cancelOnError: true,
    );

    final streamedRequest = http.StreamedRequest(request.method, request.url)
      ..headers.addAll(request.headers)
      ..contentLength = total;
    unawaited(progressController.stream.pipe(streamedRequest.sink));

    return http.Client().send(streamedRequest).timeout(kApiUploadTimeout);
  }
}
