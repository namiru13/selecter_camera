import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/camera_service.dart';

enum CameraStatus { uninitialized, ready, recording, processing, error }

class CameraState {
  final CameraStatus status;
  final CameraController? controller;
  final String? errorMessage;
  final String? lastVideoPath;

  CameraState({
    this.status = CameraStatus.uninitialized,
    this.controller,
    this.errorMessage,
    this.lastVideoPath,
  });

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    String? errorMessage,
    String? lastVideoPath,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      errorMessage: errorMessage ?? this.errorMessage,
      lastVideoPath: lastVideoPath ?? this.lastVideoPath,
    );
  }
}

class CameraViewModel extends Notifier<CameraState> {
  late final CameraService _cameraService;

  @override
  CameraState build() {
    _cameraService = ref.read(cameraServiceProvider);

    // Register disposal callback
    ref.onDispose(() {
      stopInferenceLoop();
    });

    return CameraState();
  }

  Future<void> initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (_cameraService.controller != null) {
        state = state.copyWith(
          status: CameraStatus.ready,
          controller: _cameraService.controller,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> startRecording() async {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      return;
    }
    if (state.status == CameraStatus.recording) return;

    try {
      await state.controller!.startVideoRecording();
      state = state.copyWith(status: CameraStatus.recording);
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopRecording() async {
    if (state.controller == null || !state.controller!.value.isRecordingVideo) {
      return;
    }

    try {
      final file = await state.controller!.stopVideoRecording();
      state = state.copyWith(
        status: CameraStatus.ready,
        lastVideoPath: file.path,
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Inference Loop
  bool _isProcessing = false;
  int _frameCount = 0;

  void startInferenceLoop() {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      return;
    }

    state.controller!.startImageStream((CameraImage image) {
      if (_isProcessing) return;

      _frameCount++;
      // Process every 10th frame (approx 3 FPS if 30 FPS stream)
      if (_frameCount % 10 != 0) return;

      _isProcessing = true;
      _runInference(image).whenComplete(() {
        _isProcessing = false;
      });
    });
  }

  Future<void> stopInferenceLoop() async {
    if (state.controller != null && state.controller!.value.isStreamingImages) {
      await state.controller!.stopImageStream();
    }
  }

  Future<void> _runInference(CameraImage image) async {
    // TODO: Connect with MLService
    // print('Running inference on frame $_frameCount');
  }

  // Custom dispose logic called by ref.onDispose
  void dispose() {
    stopInferenceLoop();
  }
}

final cameraViewModelProvider = NotifierProvider<CameraViewModel, CameraState>(
  CameraViewModel.new,
);
