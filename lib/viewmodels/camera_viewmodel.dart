/// カメラのViewModel
///
/// カメラの初期化、録画制御、ズーム制御、フォーカス、
/// グリッド表示、解像度設定を統合管理する。
/// 各責務は専用のサービス/コントローラーに委譲している。
library;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/camera_state.dart';
import '../services/camera_service.dart';
import '../services/settings_service.dart';
import '../services/video_save_service.dart';
import '../services/ffmpeg_service.dart';
import '../viewmodels/skiers_viewmodel.dart';

/// カメラのViewModel（Riverpod Notifier）
class CameraViewModel extends Notifier<CameraState> {
  late final CameraService _cameraService;
  late final SettingsService _settingsService;
  final VideoSaveService _videoSaveService = VideoSaveService();

  @override
  CameraState build() {
    _cameraService = ref.read(cameraServiceProvider);
    _settingsService = ref.read(settingsServiceProvider);

    // 破棄時のクリーンアップを登録
    ref.onDispose(() {
      stopInferenceLoop();
      _cameraService.dispose();
    });

    return CameraState();
  }

  /// カメラを初期化する
  Future<void> initializeCamera() async {
    try {
      // 保存された解像度設定を読み込む
      final resolution = await _settingsService.getResolutionPreset();
      final showGrid = await _settingsService.getShowGrid();
      final showSkierSelectionConfirmation = await _settingsService
          .getShowSkierSelectionOnStop();

      await _cameraService.initialize(resolutionPreset: resolution);
      if (_cameraService.controller != null) {
        final minZoom = await _cameraService.controller!.getMinZoomLevel();
        final maxZoom = await _cameraService.controller!.getMaxZoomLevel();

        state = state.copyWith(
          status: CameraStatus.ready,
          controller: _cameraService.controller,
          minZoomLevel: minZoom,
          maxZoomLevel: maxZoom,
          currentZoomLevel: 1.0.clamp(minZoom, maxZoom),
          resolutionPreset: resolution,
          showGrid: showGrid,
          showSkierSelectionConfirmation: showSkierSelectionConfirmation,
        );

        // 初期ズームを実機に反映
        await _cameraService.controller!.setZoomLevel(state.currentZoomLevel);
      }
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// カメラリソースを解放する（ライフサイクル管理用）
  Future<void> disposeCamera() async {
    await stopInferenceLoop();
    await _cameraService.dispose();
    state = CameraState();
  }

  /// ズームレベルを設定する
  Future<void> setZoomLevel(double zoom) async {
    if (state.controller == null) return;

    final newZoom = zoom.clamp(state.minZoomLevel, state.maxZoomLevel);
    await state.controller!.setZoomLevel(newZoom);
    state = state.copyWith(currentZoomLevel: newZoom);
  }

  /// フォーカスポイントを設定する
  ///
  /// [point] 正規化された座標（0.0〜1.0）
  Future<void> setFocusPoint(Offset point) async {
    if (state.controller == null) return;

    try {
      await state.controller!.setFocusPoint(point);
      await state.controller!.setFocusMode(FocusMode.auto);
      await state.controller!.setExposurePoint(point);
      state = state.copyWith(focusPoint: point);

      // 2秒後にフォーカスインジケータを消す
      Future.delayed(const Duration(seconds: 2), () {
        if (state.focusPoint == point) {
          state = state.copyWith(clearFocusPoint: true);
        }
      });
    } catch (e) {
      debugPrint('フォーカス設定エラー: $e');
    }
  }

  /// グリッド表示を切り替える
  Future<void> toggleGrid() async {
    final newShow = !state.showGrid;
    state = state.copyWith(showGrid: newShow);
    await _settingsService.setShowGrid(newShow);
  }

  /// 録画終了後の滑走者確認表示を切り替える
  Future<void> toggleShowSkierSelectionConfirmation() async {
    final newShow = !state.showSkierSelectionConfirmation;
    state = state.copyWith(showSkierSelectionConfirmation: newShow);
    await _settingsService.setShowSkierSelectionOnStop(newShow);
  }

  /// 解像度を変更する
  ///
  /// カメラの再初期化が必要なため、現在の録画状態を考慮する。
  Future<void> setResolutionPreset(ResolutionPreset preset) async {
    if (state.status == CameraStatus.recording) return;

    await _settingsService.setResolutionPreset(preset);
    state = state.copyWith(resolutionPreset: preset);

    // カメラを再初期化
    await _cameraService.dispose();
    await initializeCamera();
  }

  /// 選択された滑走者IDを設定する
  void setSelectedSkierId(String? skierId) {
    if (skierId == null) {
      state = state.copyWith(clearSelectedSkierId: true);
    } else {
      state = state.copyWith(selectedSkierId: skierId);
    }
  }

  /// 人物の選択状態を切り替える（複数選択対応）
  void togglePersonSelection(String personId) {
    final currentSelected = Set<String>.from(state.selectedPersonIds);
    if (currentSelected.contains(personId)) {
      currentSelected.remove(personId);
    } else {
      currentSelected.add(personId);
    }
    state = state.copyWith(selectedPersonIds: currentSelected);
  }

  /// 録画を開始する
  Future<void> startRecording() async {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      return;
    }
    if (state.status == CameraStatus.recording) return;

    try {
      await state.controller!.startVideoRecording();
      state = state.copyWith(
        status: CameraStatus.recording,
        recordingStartTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 録画を停止し、パスを一時保持する（ギャラリー保存は後続処理で行う）
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
      debugPrint('動画録画完了 (一時保存): ${file.path}');

      state = state.copyWith(
        status: CameraStatus.ready,
        tempVideoPath: file.path,
        clearRecordingStartTime: true,
      );
    } catch (e) {
      debugPrint('録画停止エラー: $e');
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: e.toString(),
        clearRecordingStartTime: true,
      );
    }
  }

  /// 一時保持している動画を編集（メタデータ＆サムネイル付与）してギャラリーに保存する
  Future<void> processAndSaveVideo() async {
    final videoPath = state.tempVideoPath;
    if (videoPath == null) return;

    state = state.copyWith(isSaving: true);

    try {
      final ffmpegService = FFmpegService();
      String? thumbnailImagePath;

      // 選択されている滑走者がいれば情報を取得
      final skierId = state.selectedSkierId;
      if (skierId != null) {
        final skiers = ref.read(skierViewModelProvider);
        try {
          final skier = skiers.firstWhere((s) => s.id == skierId);
          // サムネイル画像の生成
          thumbnailImagePath = await ffmpegService.generateThumbnailImage(
            skierName: skier.name,
            skierImagePath: skier.referenceImagePath,
          );
        } catch (_) {
          debugPrint('選択された滑走者ID ($skierId) に該当するデータが見つかりません');
        }
      }

      String finalVideoPath = videoPath;

      // サムネイル画像が生成されていれば動画と合成
      if (thumbnailImagePath != null) {
        final outputPath =
            '${videoPath.substring(0, videoPath.lastIndexOf('.'))}_processed.mp4';

        final success = await ffmpegService.processVideoWithThumbnail(
          sourceVideoPath: videoPath,
          thumbnailImagePath: thumbnailImagePath,
          outputPath: outputPath,
        );

        if (success) {
          finalVideoPath = outputPath;
        }

        // 後始末
        await ffmpegService.cleanupTempFiles();
      }

      // ギャラリーに保存
      final result = await _videoSaveService.saveToGallery(finalVideoPath);

      if (result.success) {
        state = state.copyWith(
          isSaving: false,
          lastVideoPath: result.savedPath,
          clearTempVideoPath: true,
        );
      } else {
        state = state.copyWith(
          isSaving: false,
          status: CameraStatus.error,
          errorMessage: result.errorMessage,
          clearTempVideoPath: true,
        );
      }
    } catch (e) {
      debugPrint('動画保存・処理エラー: $e');
      state = state.copyWith(
        isSaving: false,
        status: CameraStatus.error,
        errorMessage: e.toString(),
        clearTempVideoPath: true,
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

  Future<void> stopInferenceLoop() async {
    final controller = _cameraService.controller;
    if (controller != null && controller.value.isStreamingImages) {
      await controller.stopImageStream();
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
