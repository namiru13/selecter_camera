/// カメラサービス
///
/// カメラの初期化と制御を担当する。
/// 解像度プリセットのパラメータ化に対応。
library;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// カメラサービス
class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  /// カメラを初期化する
  ///
  /// [resolutionPreset] 解像度プリセット（デフォルト: high）
  /// [lensDirection] レンズ方向（デフォルト: back）
  Future<void> initialize({
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
    CameraLensDirection lensDirection = CameraLensDirection.back,
  }) async {
    final cameras = await availableCameras();
    // 指定されたレンズ方向のカメラを検索、見つからない場合は最初のカメラを使用
    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == lensDirection,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      resolutionPreset,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
  }

  /// カメラリソースを解放する
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}

final cameraServiceProvider = Provider((ref) => CameraService());
