/// カメラの状態を表すモデルクラス
///
/// カメラの初期化状態、録画状態、ズームレベル、フォーカスポイント、
/// グリッド表示、録画開始時刻、選択人物IDなどを管理する。
library;

import 'package:camera/camera.dart';
import 'package:flutter/painting.dart';

/// 録画終了時の滑走者選択確認の動作モード
enum ConfirmPersonSelectionMode {
  always, // 常に確認する
  onlyWhenUnselected, // 未選択時のみ確認する
  never, // 確認しない
}

/// 露出調整の動作モード
enum ExposureAdjustmentMode {
  off, // OFF
  manual, // 手動調整
  auto, // 自動調整
}

/// カメラのステータスを表すEnum
enum CameraStatus { uninitialized, ready, recording, processing, error }

/// カメラの状態を保持する不変クラス
class CameraState {
  final CameraStatus status;
  final CameraController? controller;
  final String? errorMessage;
  final String? lastVideoPath;
  final double minZoomLevel;
  final double maxZoomLevel;
  final double currentZoomLevel;

  /// タップフォーカスの位置（null = フォーカスポイントなし）
  final Offset? focusPoint;

  /// グリッドライン表示フラグ
  final bool showGrid;

  /// 水準器表示フラグ
  final bool showLeveler;

  /// 録画開始時刻（録画中のみ非null）
  final DateTime? recordingStartTime;

  /// 選択された人物ID（null = 未選択）
  final String? selectedPersonId;

  /// 現在の解像度プリセット
  final ResolutionPreset resolutionPreset;

  /// 録画終了時に滑走者選択確認を表示するモード
  final ConfirmPersonSelectionMode confirmPersonSelectionMode;

  /// 録画直後の未処理動画パス（保存処理前）
  final String? tempVideoPath;

  /// 動画保存/処理中かどうか
  final bool isSaving;

  /// 露出調整モード
  final ExposureAdjustmentMode exposureAdjustmentMode;

  /// 現在の露出オフセット値（EV）
  final double exposureOffset;

  /// 最小露出オフセット
  final double minExposureOffset;

  /// 最大露出オフセット
  final double maxExposureOffset;

  /// 露出オフセットのステップサイズ
  final double exposureOffsetStepSize;

  /// 滑走者判定機能の有効/無効
  final bool skierDetectionEnabled;

  /// 滑走者判定結果の提案人数
  final int skierDetectionProposedCount;

  CameraState({
    this.status = CameraStatus.uninitialized,
    this.controller,
    this.errorMessage,
    this.lastVideoPath,
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 1.0,
    this.currentZoomLevel = 1.0,
    this.focusPoint,
    this.showGrid = false,
    this.showLeveler = false,
    this.recordingStartTime,
    this.selectedPersonId,
    this.resolutionPreset = ResolutionPreset.high,
    this.confirmPersonSelectionMode = ConfirmPersonSelectionMode.always,
    this.tempVideoPath,
    this.isSaving = false,
    this.exposureAdjustmentMode = ExposureAdjustmentMode.off,
    this.exposureOffset = 0.0,
    this.minExposureOffset = 0.0,
    this.maxExposureOffset = 0.0,
    this.exposureOffsetStepSize = 1.0,
    this.skierDetectionEnabled = true,
    this.skierDetectionProposedCount = 3,
  });

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    String? errorMessage,
    bool? clearErrorMessage,
    String? lastVideoPath,
    double? minZoomLevel,
    double? maxZoomLevel,
    double? currentZoomLevel,
    Offset? focusPoint,
    bool? clearFocusPoint,
    bool? showGrid,
    bool? showLeveler,
    DateTime? recordingStartTime,
    bool? clearRecordingStartTime,
    String? selectedPersonId,
    bool? clearSelectedPersonId,
    ResolutionPreset? resolutionPreset,
    ConfirmPersonSelectionMode? confirmPersonSelectionMode,
    String? tempVideoPath,
    bool? clearTempVideoPath,
    bool? isSaving,
    ExposureAdjustmentMode? exposureAdjustmentMode,
    double? exposureOffset,
    double? minExposureOffset,
    double? maxExposureOffset,
    double? exposureOffsetStepSize,
    bool? skierDetectionEnabled,
    int? skierDetectionProposedCount,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      errorMessage: clearErrorMessage == true
          ? null
          : (errorMessage ?? this.errorMessage),
      lastVideoPath: lastVideoPath ?? this.lastVideoPath,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      currentZoomLevel: currentZoomLevel ?? this.currentZoomLevel,
      focusPoint: clearFocusPoint == true
          ? null
          : (focusPoint ?? this.focusPoint),
      showGrid: showGrid ?? this.showGrid,
      showLeveler: showLeveler ?? this.showLeveler,
      recordingStartTime: clearRecordingStartTime == true
          ? null
          : (recordingStartTime ?? this.recordingStartTime),
      selectedPersonId: clearSelectedPersonId == true
          ? null
          : (selectedPersonId ?? this.selectedPersonId),
      resolutionPreset: resolutionPreset ?? this.resolutionPreset,
      confirmPersonSelectionMode:
          confirmPersonSelectionMode ?? this.confirmPersonSelectionMode,
      tempVideoPath: clearTempVideoPath == true
          ? null
          : (tempVideoPath ?? this.tempVideoPath),
      isSaving: isSaving ?? this.isSaving,
      exposureAdjustmentMode:
          exposureAdjustmentMode ?? this.exposureAdjustmentMode,
      exposureOffset: exposureOffset ?? this.exposureOffset,
      minExposureOffset: minExposureOffset ?? this.minExposureOffset,
      maxExposureOffset: maxExposureOffset ?? this.maxExposureOffset,
      exposureOffsetStepSize:
          exposureOffsetStepSize ?? this.exposureOffsetStepSize,
      skierDetectionEnabled:
          skierDetectionEnabled ?? this.skierDetectionEnabled,
      skierDetectionProposedCount:
          skierDetectionProposedCount ?? this.skierDetectionProposedCount,
    );
  }
}
