import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/provider/provider_documents.dart';
import '../services/provider_document_api_service.dart';
import '../utils/constants.dart';

enum ProviderDocumentSlot { profilePhoto, cnicFront, cnicBack }

class ProviderDocumentProvider extends ChangeNotifier {
  final ProviderDocumentApiService _apiService = ProviderDocumentApiService();
  final ImagePicker _picker = ImagePicker();

  // Profile photo is a portrait selfie-style shot; CNIC images need a higher
  // resolution ceiling so printed text stays legible after compression.
  static const _profilePhotoMaxDimension = 800.0;
  static const _profilePhotoQuality = 80;
  static const _cnicMaxDimension = 1600.0;
  static const _cnicQuality = 85;

  // Freshly picked local replacements (not yet uploaded).
  File? _profilePhoto;
  File? _cnicFront;
  File? _cnicBack;

  // Already-uploaded documents, resolved to full URLs (used by the "view and
  // change existing documents" screen; empty for the post-registration flow).
  String? _profilePhotoUrl;
  String? _cnicFrontUrl;
  String? _cnicBackUrl;
  bool _isVerified = false;
  String? _verificationRemarks;

  bool _isLoadingExisting = false;
  String? _loadError;

  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;
  ProviderDocumentsModel? _uploadedDocuments;

  File? get profilePhoto => _profilePhoto;
  File? get cnicFront => _cnicFront;
  File? get cnicBack => _cnicBack;
  String? get profilePhotoUrl => _profilePhotoUrl;
  String? get cnicFrontUrl => _cnicFrontUrl;
  String? get cnicBackUrl => _cnicBackUrl;
  bool get isVerified => _isVerified;
  String? get verificationRemarks => _verificationRemarks;
  bool get isLoadingExisting => _isLoadingExisting;
  String? get loadError => _loadError;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  ProviderDocumentsModel? get uploadedDocuments => _uploadedDocuments;

  bool get canUpload =>
      (_profilePhoto != null || _profilePhotoUrl != null) &&
      (_cnicFront != null || _cnicFrontUrl != null) &&
      (_cnicBack != null || _cnicBackUrl != null);

  /// Loads the provider's currently uploaded documents (for the "view and
  /// change" screen reached from the profile page). Safe to call when the
  /// provider hasn't uploaded any documents yet.
  Future<void> loadDocuments(int providerUid) async {
    _isLoadingExisting = true;
    _loadError = null;
    notifyListeners();

    try {
      final docs = await _apiService.fetchDocuments(providerUid);
      _profilePhotoUrl = _resolveUrl(docs?.profilePhotoPath);
      _cnicFrontUrl = _resolveUrl(docs?.cnicFrontImagePath);
      _cnicBackUrl = _resolveUrl(docs?.cnicBackImagePath);
      _isVerified = docs?.isVerified ?? false;
      _verificationRemarks = docs?.verificationRemarks;
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingExisting = false;
      notifyListeners();
    }
  }

  String? _resolveUrl(String? relativePath) => relativePath == null ? null : '$kApiFileBaseUrl/$relativePath';

  Future<void> pickImage(ProviderDocumentSlot slot, ImageSource source) async {
    final isCnic = slot != ProviderDocumentSlot.profilePhoto;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: isCnic ? _cnicMaxDimension : _profilePhotoMaxDimension,
        maxHeight: isCnic ? _cnicMaxDimension : _profilePhotoMaxDimension,
        imageQuality: isCnic ? _cnicQuality : _profilePhotoQuality,
      );
      if (picked == null) return;

      final file = File(picked.path);
      switch (slot) {
        case ProviderDocumentSlot.profilePhoto:
          _profilePhoto = file;
          break;
        case ProviderDocumentSlot.cnicFront:
          _cnicFront = file;
          break;
        case ProviderDocumentSlot.cnicBack:
          _cnicBack = file;
          break;
      }
      _error = null;
      notifyListeners();
    } on PlatformException catch (e) {
      _error = _messageForPlatformException(e);
      notifyListeners();
    } catch (e) {
      _error = 'Could not access camera/gallery. Please try again.';
      notifyListeners();
    }
  }

  String _messageForPlatformException(PlatformException e) {
    switch (e.code) {
      case 'no_available_camera':
        return 'No camera is available on this device or emulator.';
      case 'camera_access_denied':
      case 'photo_access_denied':
        return 'Permission denied. Please allow camera/photo access for this app in your device settings.';
      case 'invalid_image':
        return 'The selected file is not a valid image.';
      default:
        return e.message ?? 'Could not access camera/gallery.';
    }
  }

  /// Clears a pending local replacement, reverting the slot back to whatever
  /// is already uploaded on the server (if anything).
  void removeImage(ProviderDocumentSlot slot) {
    switch (slot) {
      case ProviderDocumentSlot.profilePhoto:
        _profilePhoto = null;
        break;
      case ProviderDocumentSlot.cnicFront:
        _cnicFront = null;
        break;
      case ProviderDocumentSlot.cnicBack:
        _cnicBack = null;
        break;
    }
    notifyListeners();
  }

  Future<bool> upload(int providerUid) async {
    if (!canUpload) {
      _error = 'Please add your profile photo and both CNIC images before uploading.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      // The upload API always requires all three files, even when the caller
      // only meant to replace one - download the untouched slots' existing
      // images so they can be resent alongside the newly picked one.
      final profileFile = await _resolveFile(_profilePhoto, _profilePhotoUrl);
      final cnicFrontFile = await _resolveFile(_cnicFront, _cnicFrontUrl);
      final cnicBackFile = await _resolveFile(_cnicBack, _cnicBackUrl);

      _uploadedDocuments = await _apiService.uploadDocuments(
        providerUid: providerUid,
        profilePhoto: profileFile,
        cnicFront: cnicFrontFile,
        cnicBack: cnicBackFile,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      // Server is now the source of truth again; drop local picks and refresh URLs.
      _profilePhoto = null;
      _cnicFront = null;
      _cnicBack = null;
      _profilePhotoUrl = _resolveUrl(_uploadedDocuments?.profilePhotoPath);
      _cnicFrontUrl = _resolveUrl(_uploadedDocuments?.cnicFrontImagePath);
      _cnicBackUrl = _resolveUrl(_uploadedDocuments?.cnicBackImagePath);
      _isVerified = _uploadedDocuments?.isVerified ?? false;
      _verificationRemarks = _uploadedDocuments?.verificationRemarks;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<File> _resolveFile(File? local, String? remoteUrl) async {
    if (local != null) return local;
    if (remoteUrl == null) {
      throw Exception('Please add your profile photo and both CNIC images before uploading.');
    }

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

  void reset() {
    _profilePhoto = null;
    _cnicFront = null;
    _cnicBack = null;
    _profilePhotoUrl = null;
    _cnicFrontUrl = null;
    _cnicBackUrl = null;
    _isVerified = false;
    _verificationRemarks = null;
    _isLoadingExisting = false;
    _loadError = null;
    _isUploading = false;
    _uploadProgress = 0;
    _error = null;
    _uploadedDocuments = null;
    notifyListeners();
  }
}
