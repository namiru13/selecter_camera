/// カメラのViewModel
///
/// カメラの初期化、録画制御、ズーム制御、フォーカス、
/// グリッド表示、解像度設定を統合管理する。
/// 各責務は専用のサービス/コントローラーに委譲している。
library;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/camera_state.dart';
import '../services/camera_service.dart';
import '../services/settings_service.dart';
import '../services/video_save_service.dart';
import '../services/ffmpeg_service.dart';
import '../viewmodels/person_viewmodel.dart';

/// カメラのViewModel（Riverpod Notifier）
class CameraViewModel extends Notifier<CameraState> {
  late final CameraService _cameraService;
  late final SettingsService _settingsService;
  late final VideoSaveService _videoSaveService;

  @override
  CameraState build() {
    _cameraService = ref.read(cameraServiceProvider);
    _settingsService = ref.read(settingsServiceProvider);
    _videoSaveService = ref.read(videoSaveServiceProvider);

    // 破棄時のクリーンアップを登録
    ref.onDispose(() {
      _cameraService.dispose();
    });

    return CameraState();
  }

  /// カメラを初期化する
  Future<void> initializeCamera() async {
    try {
      // 保存された設定を読み込む
      final resolution = await _settingsService.getResolutionPreset();
      final showGrid = await _settingsService.getShowGrid();
      final confirmPersonSelectionMode = await _settingsService
          .getConfirmPersonSelectionMode();
      final exposureAdjustmentMode = await _settingsService
          .getExposureAdjustmentMode();
      final exposureOffset = await _settingsService.getExposureOffset();
      final showLeveler = await _settingsService.getShowLeveler();
      final skierDetectionEnabled = await _settingsService.getSkierDetectionEnabled();
      final skierDetectionProposedCount = await _settingsService.getSkierDetectionProposedCount();

      await _cameraService.initialize(resolutionPreset: resolution);
      final controller = _cameraService.controller;
      if (controller != null) {
        final minZoom = await controller.getMinZoomLevel();
        final maxZoom = await controller.getMaxZoomLevel();

        // 露出設定の範囲とステップサイズを取得
        final minExposure = await controller.getMinExposureOffset();
        final maxExposure = await controller.getMaxExposureOffset();
        final exposureStep = await controller.getExposureOffsetStepSize();

        // 露出設定を適用
        try {
          switch (exposureAdjustmentMode) {
            case ExposureAdjustmentMode.off:
              await controller.setExposureOffset(0.0);
              break;
            case ExposureAdjustmentMode.manual:
              await controller.setExposureOffset(
                exposureOffset.clamp(minExposure, maxExposure),
              );
              break;
            case ExposureAdjustmentMode.auto:
              // 自動調整モード
              await controller.setExposureMode(ExposureMode.auto);
              break;
          }
        } catch (e) {
          debugPrint('露出設定適用エラー: $e');
        }

        state = state.copyWith(
          status: CameraStatus.ready,
          controller: controller,
          minZoomLevel: minZoom,
          maxZoomLevel: maxZoom,
          currentZoomLevel: 1.0.clamp(minZoom, maxZoom),
          resolutionPreset: resolution,
          showGrid: showGrid,
          showLeveler: showLeveler,
          confirmPersonSelectionMode: confirmPersonSelectionMode,
          exposureAdjustmentMode: exposureAdjustmentMode,
          exposureOffset: exposureOffset,
          minExposureOffset: minExposure,
          maxExposureOffset: maxExposure,
          exposureOffsetStepSize: exposureStep,
          skierDetectionEnabled: skierDetectionEnabled,
          skierDetectionProposedCount: skierDetectionProposedCount,
          // 前回のエラーメッセージをクリアする
          clearErrorMessage: true,
        );

        // 初期ズームを実機に反映
        await controller.setZoomLevel(state.currentZoomLevel);
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

  /// 露出モードを切り替える
  Future<void> setExposureAdjustmentMode(ExposureAdjustmentMode mode) async {
    if (state.controller == null) return;

    try {
      switch (mode) {
        case ExposureAdjustmentMode.off:
          await state.controller!.setExposureOffset(0.0);
          state = state.copyWith(
            exposureAdjustmentMode: mode,
            exposureOffset: 0.0,
          );
          await _settingsService.setExposureOffset(0.0);
          break;
        case ExposureAdjustmentMode.manual:
          // 手動モードへ。現在のオフセットを維持
          await state.controller!.setExposureOffset(state.exposureOffset);
          state = state.copyWith(exposureAdjustmentMode: mode);
          break;
        case ExposureAdjustmentMode.auto:
          // 自動調整モードへ
          await state.controller!.setExposureMode(ExposureMode.auto);
          state = state.copyWith(exposureAdjustmentMode: mode);
          break;
      }
      await _settingsService.setExposureAdjustmentMode(mode);
    } catch (e) {
      debugPrint('露出モード切り替えエラー: $e');
    }
  }

  /// 露出オフセットを設定する
  Future<void> setExposureOffset(double offset) async {
    if (state.controller == null) return;

    try {
      final clampedOffset = offset.clamp(
        state.minExposureOffset,
        state.maxExposureOffset,
      );
      await state.controller!.setExposureOffset(clampedOffset);
      state = state.copyWith(exposureOffset: clampedOffset);
      await _settingsService.setExposureOffset(clampedOffset);
    } catch (e) {
      debugPrint('露出オフセット設定エラー: $e');
    }
  }

  /// グリッド表示を切り替える
  Future<void> toggleGrid() async {
    final newShow = !state.showGrid;
    state = state.copyWith(showGrid: newShow);
    await _settingsService.setShowGrid(newShow);
  }

  /// 水準器表示を切り替える
  Future<void> toggleLeveler() async {
    final newShow = !state.showLeveler;
    state = state.copyWith(showLeveler: newShow);
    await _settingsService.setShowLeveler(newShow);
  }

  /// 録画終了後の人物確認表示モードを設定する
  Future<void> setConfirmPersonSelectionMode(
    ConfirmPersonSelectionMode mode,
  ) async {
    state = state.copyWith(confirmPersonSelectionMode: mode);
    await _settingsService.setConfirmPersonSelectionMode(mode);
  }

  /// 滑走者判定機能の有効/無効を設定する
  Future<void> setSkierDetectionEnabled(bool enabled) async {
    state = state.copyWith(skierDetectionEnabled: enabled);
    await _settingsService.setSkierDetectionEnabled(enabled);
  }

  /// 滑走者判定結果の提案人数を設定する
  Future<void> setSkierDetectionProposedCount(int count) async {
    state = state.copyWith(skierDetectionProposedCount: count);
    await _settingsService.setSkierDetectionProposedCount(count);
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

  /// 選択された人物IDを設定する
  void setSelectedPersonId(String? personId) {
    if (personId == null) {
      state = state.copyWith(clearSelectedPersonId: true);
    } else {
      // 同じ人物をもう一度タップした場合は選択解除
      if (state.selectedPersonId == personId) {
        state = state.copyWith(clearSelectedPersonId: true);
      } else {
        state = state.copyWith(selectedPersonId: personId);
      }
    }
  }

  /// 録画を開始する
  Future<void> startRecording(DeviceOrientation orientation) async {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      return;
    }
    if (state.status == CameraStatus.recording) return;

    try {
      await state.controller!.lockCaptureOrientation(orientation);
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
            // AI推論モックを実行して人物を自動判定
      final personsAsync = ref.read(personViewModelProvider);
      final persons = personsAsync.value ?? [];
      final predictedPersonId = await _aiInferenceService.predictTargetPerson(persons);
      
      if (predictedPersonId != null) {
        // AIが判定した人物をセット
        state = state.copyWith(selectedPersonId: predictedPersonId);
      }
      // イメージストリームが動作中の場合は先に停止する（競合防止）
      if (state.controller!.value.isStreamingImages) {
        await state.controller!.stopImageStream();
      }

      final file = await state.controller!.stopVideoRecording();
      await state.controller!.unlockCaptureOrientation();
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

      // 選択されている人物がいれば情報を取得
      final personId = state.selectedPersonId;
      if (personId != null) {
        final personsAsync = ref.read(personViewModelProvider);
        final persons = personsAsync.value;
        if (persons != null) {
          try {
            final person = persons.firstWhere((p) => p.id == personId);
            // サムネイル画像の生成
            thumbnailImagePath = await ffmpegService.generateThumbnailImage(
              personName: person.name,
              personImagePath: person.thumbnailPath,
            );
          } catch (_) {
            debugPrint('選択された人物ID ($personId) に該当するデータが見つかりません');
          }
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
          thumbnailDuration: 0.1, // サムネイル画像の表示時間を0.1秒にする
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
}

/// CameraViewModelのRiverpod Provider
final cameraViewModelProvider = NotifierProvider<CameraViewModel, CameraState>(
  CameraViewModel.new,
);
