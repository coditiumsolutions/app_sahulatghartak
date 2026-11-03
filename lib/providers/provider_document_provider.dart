import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../data/repositories/provider_document_repository.dart';
import '../models/provider/provider_documents.dart';
import '../utils/api_error.dart';

enum ProviderDocumentSlot {
  profilePhoto,
  cnicFront,
  cnicBack,
  policeVerification
}

class ProviderDocumentProvider extends ChangeNotifier {
  ProviderDocumentProvider({required ProviderDocumentRepository repository})
      : _repository = repository;

  final ProviderDocumentRepository _repository;

  // Profile photo is a portrait selfie-style shot; CNIC images need a higher
  // resolution ceiling so printed text stays legible after compression.
  // These are enforced here (rather than relying on ImagePicker's built-in
  // downscaling, which no longer runs now that capture/crop happens before
  // this provider is touched) so a high-res takePicture()/gallery source
  // never silently blows past the API's 5MB-per-file limit.
  static const _profilePhotoMaxDimension = 800;
  static const _profilePhotoQuality = 80;
  static const _cnicMaxDimension = 1600;
  static const _cnicQuality = 85;

  // Freshly picked local replacements (not yet uploaded).
  File? _profilePhoto;
  File? _cnicFront;
  File? _cnicBack;
  File? _policeVerification;

  // Already-uploaded documents, resolved to full URLs (used by the "view and
  // change existing documents" screen; empty for the post-registration flow).
  String? _profilePhotoUrl;
  String? _cnicFrontUrl;
  String? _cnicBackUrl;
  String? _policeVerificationUrl;
  bool _isVerified = false;
  DateTime? _verifiedOn;
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
  File? get policeVerification => _policeVerification;
  String? get profilePhotoUrl => _profilePhotoUrl;
  String? get cnicFrontUrl => _cnicFrontUrl;
  String? get cnicBackUrl => _cnicBackUrl;
  String? get policeVerificationUrl => _policeVerificationUrl;
  bool get isVerified => _isVerified;
  DateTime? get verifiedOn => _verifiedOn;
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

  /// Whether any slot has a freshly picked local replacement waiting to be
  /// saved - used by the "view/edit documents" screen to disable Save Changes
  /// when nothing was actually changed, since a no-op save would still be a
  /// wasted round trip.
  bool get hasChanges =>
      _profilePhoto != null ||
      _cnicFront != null ||
      _cnicBack != null ||
      _policeVerification != null;

  /// Loads the provider's currently uploaded documents (for the "view and
  /// change" screen reached from the profile page). Safe to call when the
  /// provider hasn't uploaded any documents yet.
  Future<void> loadDocuments(int providerUid) async {
    _isLoadingExisting = true;
    _loadError = null;
    notifyListeners();

    try {
      final docs = await _repository.fetchDocuments(providerUid);
      final version = docs?.updatedOn ?? docs?.createdOn;
      _profilePhotoUrl =
          _repository.resolveUrl(docs?.profilePhotoPath, version: version);
      _cnicFrontUrl =
          _repository.resolveUrl(docs?.cnicFrontImagePath, version: version);
      _cnicBackUrl =
          _repository.resolveUrl(docs?.cnicBackImagePath, version: version);
      _policeVerificationUrl = _repository
          .resolveUrl(docs?.policeVerificationPath, version: version);
      _isVerified = docs?.isVerified ?? false;
      _verifiedOn = docs?.verifiedOn;
      _verificationRemarks = docs?.verificationRemarks;
    } catch (e) {
      _loadError = friendlyErrorMessage(e);
    } finally {
      _isLoadingExisting = false;
      notifyListeners();
    }
  }

  /// Stores an already-captured/cropped [file] for [slot]. Capture (live
  /// camera or gallery+crop) happens entirely in the UI layer before this is
  /// called - this only re-encodes to stay within the API's per-file size
  /// ceiling and records the result.
  Future<void> setPickedImage(ProviderDocumentSlot slot, File file) async {
    try {
      final isCnic = slot == ProviderDocumentSlot.cnicFront ||
          slot == ProviderDocumentSlot.cnicBack ||
          slot == ProviderDocumentSlot.policeVerification;
      final resolved = await _enforceSizeLimit(
        file,
        maxDimension: isCnic ? _cnicMaxDimension : _profilePhotoMaxDimension,
        quality: isCnic ? _cnicQuality : _profilePhotoQuality,
      );

      switch (slot) {
        case ProviderDocumentSlot.profilePhoto:
          _profilePhoto = resolved;
          break;
        case ProviderDocumentSlot.cnicFront:
          _cnicFront = resolved;
          break;
        case ProviderDocumentSlot.cnicBack:
          _cnicBack = resolved;
          break;
        case ProviderDocumentSlot.policeVerification:
          _policeVerification = resolved;
          break;
      }
      _error = null;
      notifyListeners();
    } on PlatformException catch (e) {
      _error = _messageForPlatformException(e);
      notifyListeners();
    } catch (e) {
      _error = 'Could not process the selected image. Please try again.';
      notifyListeners();
    }
  }

  /// Downscales/re-encodes [file] if it exceeds [maxDimension] on its longest
  /// side, so neither a full-resolution `takePicture()` output nor a
  /// gallery-sourced image can silently exceed the API's 5MB-per-file limit.
  /// Falls back to the original file if decoding fails.
  Future<File> _enforceSizeLimit(File file,
      {required int maxDimension, required int quality}) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    final longestSide =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longestSide > maxDimension
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxDimension : null,
            height: decoded.height > decoded.width ? maxDimension : null,
          )
        : decoded;

    final dir = await getTemporaryDirectory();
    final outFile =
        File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}_doc.jpg');
    await outFile.writeAsBytes(img.encodeJpg(resized, quality: quality));
    return outFile;
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
      case ProviderDocumentSlot.policeVerification:
        _policeVerification = null;
        break;
    }
    notifyListeners();
  }

  /// Used by the initial provider-registration flow, where no documents
  /// exist on the server yet: [canUpload] already guarantees every slot has
  /// a freshly picked local file (there's no existing URL to fall back to
  /// this early), so all three are always sent together.
  Future<bool> upload(int providerUid) => _submit(providerUid);

  /// Used by the "view/edit documents" screen to replace only the slot(s)
  /// the provider actually changed. Unlike [upload], slots left untouched
  /// (only an existing [_profilePhotoUrl]/etc., no fresh local pick) are
  /// simply omitted from the request instead of being downloaded from the
  /// server and re-uploaded - the backend now preserves whatever wasn't
  /// resent (see the "Upload Provider Documents" section of api.txt).
  Future<bool> saveChanges(int providerUid) => _submit(providerUid);

  Future<bool> _submit(int providerUid) async {
    if (!canUpload) {
      _error =
          'Please add your profile photo and both CNIC images before uploading.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      _uploadedDocuments = await _repository.upload(
        providerUid: providerUid,
        profilePhoto: _profilePhoto,
        cnicFront: _cnicFront,
        cnicBack: _cnicBack,
        policeVerification: _policeVerification,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      // Server is now the source of truth again; drop local picks and refresh URLs.
      // Re-derive the version from this response's own updatedOn so the
      // just-uploaded image(s) get a fresh cache-busted URL immediately,
      // without waiting for a cold start or manual pull-to-refresh.
      _profilePhoto = null;
      _cnicFront = null;
      _cnicBack = null;
      _policeVerification = null;
      final version =
          _uploadedDocuments?.updatedOn ?? _uploadedDocuments?.createdOn;
      _profilePhotoUrl = _repository
          .resolveUrl(_uploadedDocuments?.profilePhotoPath, version: version);
      _cnicFrontUrl = _repository
          .resolveUrl(_uploadedDocuments?.cnicFrontImagePath, version: version);
      _cnicBackUrl = _repository
          .resolveUrl(_uploadedDocuments?.cnicBackImagePath, version: version);
      _policeVerificationUrl = _repository.resolveUrl(
          _uploadedDocuments?.policeVerificationPath,
          version: version);
      _isVerified = _uploadedDocuments?.isVerified ?? false;
      _verifiedOn = _uploadedDocuments?.verifiedOn;
      _verificationRemarks = _uploadedDocuments?.verificationRemarks;
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e);
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Clears stale local state before a fresh [loadDocuments] call. Does NOT
  /// touch [_isVerified]/[_verificationRemarks] - this provider is a shared
  /// singleton, and `ProviderDashboardScreen` reactively watches it to bounce
  /// a provider out if verification is revoked while they're already inside
  /// the dashboard. Forcing `_isVerified` to false here (even momentarily,
  /// before the real value comes back from the server) was mistaken by that
  /// watcher for an actual revocation, replacing the screen the provider had
  /// just opened with the verification-pending block - the "loops back to
  /// the same error" bug. `loadDocuments` overwrites both fields with the
  /// authoritative server value immediately after this, so leaving them as
  /// they are here is safe.
  void reset() {
    _profilePhoto = null;
    _cnicFront = null;
    _cnicBack = null;
    _policeVerification = null;
    _profilePhotoUrl = null;
    _cnicFrontUrl = null;
    _cnicBackUrl = null;
    _policeVerificationUrl = null;
    _isLoadingExisting = false;
    _loadError = null;
    _isUploading = false;
    _uploadProgress = 0;
    _error = null;
    _uploadedDocuments = null;
    notifyListeners();
  }
}
