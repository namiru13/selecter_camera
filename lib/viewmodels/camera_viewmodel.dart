/// カメラのViewModel
///
/// カメラの初期化、録画制御、ズーム制御を統合管理する。
/// 各責務は専用のサービス/コントローラーに委譲している。
library;

import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/camera_state.dart';
import '../services/camera_service.dart';
import '../services/orientation_service.dart';
import '../services/video_save_service.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/// カメラのViewModel（Riverpod Notifier）
class CameraViewModel extends Notifier<CameraState> {
  late final CameraService _cameraService;
  late final OrientationService _orientationService;
  final VideoSaveService _videoSaveService = VideoSaveService();

  @override
  CameraState build() {
    _cameraService = ref.read(cameraServiceProvider);
    _orientationService = OrientationService();

    // デバイスの向き変更を監視
    _orientationService.startListening((orientation) {
      if (state.sensorOrientation != orientation) {
        state = state.copyWith(sensorOrientation: orientation);
        _updateCameraOrientation(orientation);
      }
    });

    // 破棄時のクリーンアップを登録
    ref.onDispose(() {
      _orientationService.stopListening();
      stopInferenceLoop();
    });

    return CameraState();
  }

  /// カメラの向きを更新する
  Future<void> _updateCameraOrientation(
    NativeDeviceOrientation orientation,
  ) async {
    if (state.controller == null) return;
    await OrientationService.lockCaptureOrientation(
      state.controller!,
      orientation,
    );
  }

  /// カメラを初期化する
  Future<void> initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (_cameraService.controller != null) {
        final minZoom = await _cameraService.controller!.getMinZoomLevel();
        final maxZoom = await _cameraService.controller!.getMaxZoomLevel();

        state = state.copyWith(
          status: CameraStatus.ready,
          controller: _cameraService.controller,
          minZoomLevel: minZoom,
          maxZoomLevel: maxZoom,
          currentZoomLevel: minZoom,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// ズームレベルを設定する
  Future<void> setZoomLevel(double zoom) async {
    if (state.controller == null) return;

    final newZoom = zoom.clamp(state.minZoomLevel, state.maxZoomLevel);
    await state.controller!.setZoomLevel(newZoom);
    state = state.copyWith(currentZoomLevel: newZoom);
  }

  /// 録画を開始する
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

  /// 録画を停止し、ギャラリーに保存する
  Future<void> stopRecording() async {
    if (state.controller == null || !state.controller!.value.isRecordingVideo) {
      return;
    }

    try {
      // イメージストリームが動作中の場合は先に停止する（競合防止）
      if (state.controller!.value.isStreamingImages) {
        await state.controller!.stopImageStream();
      }

      final file = await state.controller!.stopVideoRecording();
      debugPrint('動画録画完了: ${file.path}');

      // ギャラリーに保存
      final result = await _videoSaveService.saveToGallery(file.path);

      if (result.success) {
        state = state.copyWith(
          status: CameraStatus.ready,
          lastVideoPath: file.path,
        );
      } else {
        state = state.copyWith(
          status: CameraStatus.error,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // === 推論ループ ===
  bool _isProcessing = false;
  int _frameCount = 0;

  /// 推論ループを開始する
  void startInferenceLoop() {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      return;
    }

    state.controller!.startImageStream((CameraImage image) {
      if (_isProcessing) return;

      _frameCount++;
      if (_frameCount % 10 != 0) return;

      _isProcessing = true;
      _runInference(image).whenComplete(() {
        _isProcessing = false;
      });
    });
  }

  /// 推論ループを停止する
  Future<void> stopInferenceLoop() async {
    if (state.controller != null && state.controller!.value.isStreamingImages) {
      await state.controller!.stopImageStream();
    }
  }

  /// 推論を実行する（TODO: MLServiceと接続）
  Future<void> _runInference(CameraImage image) async {
    // TODO: MLServiceと接続
  }
}

/// CameraViewModelのRiverpod Provider
final cameraViewModelProvider = NotifierProvider<CameraViewModel, CameraState>(
  CameraViewModel.new,
);
