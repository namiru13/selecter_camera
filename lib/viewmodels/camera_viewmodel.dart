import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import '../services/camera_service.dart';

enum CameraStatus { uninitialized, ready, recording, processing, error }

class CameraState {
  final CameraStatus status;
  final CameraController? controller;
  final String? errorMessage;
  final String? lastVideoPath;
  final double minZoomLevel;
  final double maxZoomLevel;
  final double currentZoomLevel;

  CameraState({
    this.status = CameraStatus.uninitialized,
    this.controller,
    this.errorMessage,
    this.lastVideoPath,
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 1.0,
    this.currentZoomLevel = 1.0,
  });

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    String? errorMessage,
    String? lastVideoPath,
    double? minZoomLevel,
    double? maxZoomLevel,
    double? currentZoomLevel,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      errorMessage: errorMessage ?? this.errorMessage,
      lastVideoPath: lastVideoPath ?? this.lastVideoPath,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      currentZoomLevel: currentZoomLevel ?? this.currentZoomLevel,
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

  Future<void> setZoomLevel(double zoom) async {
    if (state.controller == null) return;

    final newZoom = zoom.clamp(state.minZoomLevel, state.maxZoomLevel);
    await state.controller!.setZoomLevel(newZoom);
    state = state.copyWith(currentZoomLevel: newZoom);
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
      // イメージストリームが動作中の場合は先に停止する（競合防止）
      if (state.controller!.value.isStreamingImages) {
        await state.controller!.stopImageStream();
      }

      final file = await state.controller!.stopVideoRecording();
      debugPrint('動画録画完了: ${file.path}');

      final sourceFile = File(file.path);
      if (!await sourceFile.exists()) {
        throw Exception('録画ファイルが見つかりません: ${file.path}');
      }
      debugPrint('ファイルサイズ: ${await sourceFile.length()} bytes');

      // 安定したパスにコピー（一時ファイルの無効化を防ぐ）
      final tempDir = await getTemporaryDirectory();
      final stablePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final stableFile = await sourceFile.copy(stablePath);
      debugPrint('安定パスにコピー完了: ${stableFile.path}');

      // ギャラリーに保存
      debugPrint('ギャラリーへの保存を開始...');
      await Gal.putVideo(stableFile.path);
      debugPrint('ギャラリーへの保存成功');

      // 一時コピーファイルの削除
      try {
        await stableFile.delete();
      } catch (_) {}

      state = state.copyWith(
        status: CameraStatus.ready,
        lastVideoPath: file.path,
      );
    } on GalException catch (e) {
      debugPrint('GalException: ${e.type} - ${e.toString()}');
      // PlatformException の詳細情報をログ出力
      debugPrint('PlatformException詳細: ${e.platformException.message}');
      debugPrint('ネイティブStackTrace: ${e.platformException.stacktrace}');
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'ギャラリー保存エラー: ${e.type.message}',
      );
    } catch (e) {
      debugPrint('不明なエラー: $e');
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
