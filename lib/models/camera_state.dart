/// カメラの状態を表すモデルクラス
///
/// カメラの初期化状態、録画状態、ズームレベル、デバイスの向きなどを管理する。
library;

import 'package:camera/camera.dart';

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
