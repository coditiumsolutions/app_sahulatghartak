import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../widgets/frosted_icon_button.dart';

import '../../providers/provider_document_provider.dart';
import '../../services/camera_permission_service.dart';
import '../../services/frame_validators/cnic_frame_validator.dart';
import '../../services/frame_validators/face_frame_validator.dart';
import '../../utils/camera_image_converter.dart';
import '../../utils/capture_crop_mapper.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/provider/capture_outline_painter.dart';

/// Live camera capture with a real-time framing guide: shows a face-oval or
/// CNIC-card outline over the preview, gates the shutter on live detection
/// (a face for the profile photo; OCR/barcode signals of a genuine CNIC for
/// the front/back), and crops the captured photo to the outline before
/// returning it. Pops `null` if the user backs out without capturing.
class LiveCameraCaptureScreen extends StatefulWidget {
  const LiveCameraCaptureScreen({super.key, required this.slot});

  final ProviderDocumentSlot slot;

  @override
  State<LiveCameraCaptureScreen> createState() =>
      _LiveCameraCaptureScreenState();
}

class _FrameState {
  const _FrameState(
      {this.warmedUp = false,
      this.isValid = false,
      this.message = 'Preparing scanner...'});
  final bool warmedUp;
  final bool isValid;
  final String message;
}

enum _PermissionUiState { checking, granted, denied, permanentlyDenied }

class _LiveCameraCaptureScreenState extends State<LiveCameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _description;
  bool _initializing = true;
  String? _initError;
  _PermissionUiState _permissionState = _PermissionUiState.checking;

  FaceFrameValidator? _faceValidator;
  CnicFrameValidator? _cnicValidator;

  final ValueNotifier<_FrameState> _frameState =
      ValueNotifier(const _FrameState());
  bool _isBusy = false;
  DateTime? _lastRun;
  bool _isCapturing = false;
  bool _disposed = false;
  Size _previewBoxSize = Size.zero;
  bool _loggedFrameDiagnostics = false;

  bool get _isBack => widget.slot == ProviderDocumentSlot.cnicBack;

  OutlineShape get _shape => widget.slot == ProviderDocumentSlot.profilePhoto
      ? OutlineShape.faceOval
      : OutlineShape.cnicCard;

  CameraLensDirection get _lensDirection =>
      widget.slot == ProviderDocumentSlot.profilePhoto
          ? CameraLensDirection.front
          : CameraLensDirection.back;

  String get _defaultMessage {
    switch (widget.slot) {
      case ProviderDocumentSlot.profilePhoto:
        return 'Position your face in the oval';
      case ProviderDocumentSlot.cnicFront:
        return 'Align your CNIC (front) within the frame';
      case ProviderDocumentSlot.cnicBack:
        return 'Align your CNIC (back) within the frame';
      case ProviderDocumentSlot.policeVerification:
        return 'Align the document within the frame';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _teardownCamera();
      if (mounted) setState(() => _initializing = true);
    } else if (state == AppLifecycleState.resumed &&
        _permissionState == _PermissionUiState.granted) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _initError = null;
    });

    final permissionResult =
        await CameraPermissionService().ensureCameraPermission();
    if (!mounted) return;
    if (permissionResult != CameraPermissionResult.granted) {
      setState(() {
        _initializing = false;
        _permissionState =
            permissionResult == CameraPermissionResult.permanentlyDenied
                ? _PermissionUiState.permanentlyDenied
                : _PermissionUiState.denied;
      });
      return;
    }
    _permissionState = _PermissionUiState.granted;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty)
        throw Exception('No camera is available on this device.');
      final description = cameras.firstWhere(
          (c) => c.lensDirection == _lensDirection,
          orElse: () => cameras.first);
      _description = description;

      final controller = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      // Some devices default a fresh CameraController to a non-1.0x zoom
      // level, which makes the live framing guide feel unnecessarily tight
      // (user has to back away further than expected to fit in it). Force
      // the minimum zoom explicitly rather than trusting the device default.
      try {
        final minZoom = await controller.getMinZoomLevel();
        await controller.setZoomLevel(minZoom);
      } catch (_) {}
      _controller = controller;

      if (widget.slot == ProviderDocumentSlot.profilePhoto) {
        _faceValidator = FaceFrameValidator();
      } else {
        _cnicValidator = CnicFrameValidator();
      }
      _frameState.value = _FrameState(message: _defaultMessage);

      await controller.startImageStream(_onFrame);
      if (!mounted) return;
      setState(() => _initializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initError = 'Could not start the camera. Please try again.';
      });
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_isBusy || _disposed) return;
    final now = DateTime.now();
    if (_lastRun != null &&
        now.difference(_lastRun!) < const Duration(milliseconds: 350)) return;
    _isBusy = true;
    _lastRun = now;

    try {
      final controller = _controller;
      final description = _description;
      if (controller == null || description == null) return;

      final inputImage = CameraImageConverter.toInputImage(
        image,
        description: description,
        deviceOrientation: controller.value.deviceOrientation,
      );
      if (inputImage == null) {
        if (!_loggedFrameDiagnostics) {
          _loggedFrameDiagnostics = true;
          debugPrint(
            'LiveCameraCaptureScreen: dropped frame - could not build InputImage '
            '(format=${image.format.group}/${image.format.raw}, planes=${image.planes.length}, '
            'deviceOrientation=${controller.value.deviceOrientation})',
          );
        }
        return;
      }
      if (_disposed) return;

      // On first use, ML Kit's on-device models are fetched via Google Play
      // Services' Optional Module downloader rather than being fully bundled
      // offline - without Play Services/Play Store (common on emulator
      // images) or without internet, that download can stall indefinitely.
      // A hard timeout here means a stuck model load surfaces as a retryable
      // "taking longer than usual" state instead of hanging forever with
      // _isBusy never resetting.
      const detectionTimeout = Duration(seconds: 5);
      bool isValid;
      if (widget.slot == ProviderDocumentSlot.profilePhoto) {
        isValid =
            await (_faceValidator?.hasFace(inputImage) ?? Future.value(false))
                .timeout(detectionTimeout, onTimeout: () => false);
      } else {
        final result =
            await (_cnicValidator?.validate(inputImage, isBack: _isBack) ??
                    Future.value(FrameValidationResult.invalid))
                .timeout(detectionTimeout,
                    onTimeout: () => FrameValidationResult.invalid);
        isValid = result.isValid;
      }
      if (_disposed) return;

      _frameState.value = _FrameState(
        warmedUp: true,
        isValid: isValid,
        message: isValid ? 'Detected - hold still' : _defaultMessage,
      );
    } catch (e, st) {
      // A single bad frame shouldn't crash the stream - just skip it, but
      // log it so a persistently-stuck "Preparing scanner..." state is
      // diagnosable instead of silently invisible.
      if (!_loggedFrameDiagnostics) {
        _loggedFrameDiagnostics = true;
        debugPrint('LiveCameraCaptureScreen: frame processing error: $e\n$st');
      }
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    final state = _frameState.value;
    if (controller == null || _isCapturing || !state.warmedUp || !state.isValid)
      return;

    setState(() => _isCapturing = true);
    try {
      final picture = await controller.takePicture();
      final outlineRect =
          CaptureOutlineGeometry.rectFor(_previewBoxSize, _shape);
      final cropped = await CaptureCropMapper.cropToOutline(
        imageFile: File(picture.path),
        outlineRect: outlineRect,
        previewWidgetSize: _previewBoxSize,
      );
      if (!mounted) return;
      Navigator.of(context).pop(cropped ?? File(picture.path));
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'Could not capture photo. Please try again.',
          type: AppToastType.error);
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _teardownCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages)
          await controller.stopImageStream();
      } catch (_) {}
      try {
        await controller.dispose();
      } catch (_) {}
    }
    await _faceValidator?.close();
    await _cnicValidator?.close();
    _faceValidator = null;
    _cnicValidator = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _teardownCamera();
    _frameState.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();
    final isLandscapeSensor = previewSize.width > previewSize.height;
    final displaySize = isLandscapeSensor
        ? Size(previewSize.height, previewSize.width)
        : previewSize;

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: displaySize.width,
            height: displaySize.height,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_permissionState == _PermissionUiState.denied ||
                _permissionState == _PermissionUiState.permanentlyDenied)
              _buildPermissionDenied()
            else if (_initError != null)
              _buildError(_initError!)
            else if (_initializing || _controller == null)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white))
            else
              _buildCaptureUi(_controller!),
            Positioned(
              top: 12,
              left: 4,
              child: FrostedBackButton(
                  onPressed: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureUi(CameraController controller) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _previewBoxSize =
                  Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(controller),
                  ValueListenableBuilder<_FrameState>(
                    valueListenable: _frameState,
                    builder: (context, state, _) => CustomPaint(
                      painter: CaptureOutlinePainter(
                          shape: _shape, isValid: state.isValid),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ValueListenableBuilder<_FrameState>(
            valueListenable: _frameState,
            builder: (context, state, _) {
              final enabled = state.warmedUp && state.isValid && !_isCapturing;
              return Column(
                children: [
                  Text(
                    state.warmedUp ? state.message : 'Preparing scanner...',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: enabled ? _capture : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            enabled ? const Color(0xFF2ECC71) : Colors.white24,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    final permanently =
        _permissionState == _PermissionUiState.permanentlyDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              permanently
                  ? 'Camera access is disabled for this app. Please allow it in your device settings.'
                  : 'Camera permission is needed to capture this document.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: permanently
                  ? () => CameraPermissionService().openSettings()
                  : _initCamera,
              child: Text(permanently ? 'Open Settings' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _initCamera, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
