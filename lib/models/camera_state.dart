/// カメラの状態を表すモデルクラス
///
/// カメラの初期化状態、録画状態、ズームレベル、フォーカスポイント、
/// グリッド表示、録画開始時刻、選択滑走者IDなどを管理する。
library;

import 'package:camera/camera.dart';
import 'package:flutter/painting.dart';

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

  /// 録画開始時刻（録画中のみ非null）
  final DateTime? recordingStartTime;

  /// 選択された滑走者ID（null = 未選択）
  final String? selectedSkierId;

  /// 選択された人物IDのセット（空 = 誰も選択されていない）
  final Set<String> selectedPersonIds;

  /// 現在の解像度プリセット
  final ResolutionPreset resolutionPreset;

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
    this.recordingStartTime,
    this.selectedSkierId,
    this.selectedPersonIds = const {},
    this.resolutionPreset = ResolutionPreset.high,
  });

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    String? errorMessage,
    String? lastVideoPath,
    double? minZoomLevel,
    double? maxZoomLevel,
    double? currentZoomLevel,
    Offset? focusPoint,
    bool? clearFocusPoint,
    bool? showGrid,
    DateTime? recordingStartTime,
    bool? clearRecordingStartTime,
    String? selectedSkierId,
    bool? clearSelectedSkierId,
    Set<String>? selectedPersonIds,
    ResolutionPreset? resolutionPreset,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      errorMessage: errorMessage ?? this.errorMessage,
      lastVideoPath: lastVideoPath ?? this.lastVideoPath,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      currentZoomLevel: currentZoomLevel ?? this.currentZoomLevel,
      focusPoint: clearFocusPoint == true
          ? null
          : (focusPoint ?? this.focusPoint),
      showGrid: showGrid ?? this.showGrid,
      recordingStartTime: clearRecordingStartTime == true
          ? null
          : (recordingStartTime ?? this.recordingStartTime),
      selectedSkierId: clearSelectedSkierId == true
          ? null
          : (selectedSkierId ?? this.selectedSkierId),
      selectedPersonIds: selectedPersonIds ?? this.selectedPersonIds,
      resolutionPreset: resolutionPreset ?? this.resolutionPreset,
    );
  }
}
