/// デバイス向き検出サービス
///
/// ネイティブセンサーからデバイスの向きを検出し、
/// カメラのキャプチャ方向に変換するサービス。
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/// デバイスの向きを監視し、カメラの向きに変換するサービス
class OrientationService {
  StreamSubscription<NativeDeviceOrientation>? _subscription;

  /// デバイスの向き変更を監視し、コールバックで通知する
  void startListening(void Function(NativeDeviceOrientation) onChanged) {
    final communicator = NativeDeviceOrientationCommunicator();
    _subscription = communicator
        .onOrientationChanged(useSensor: true)
        .listen(onChanged);
  }

  /// 監視を停止する
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// NativeDeviceOrientationをFlutterのDeviceOrientationに変換する
  ///
  /// カメラセンサーの向きが逆のため、landscape方向は反転する
  static DeviceOrientation toDeviceOrientation(
    NativeDeviceOrientation orientation,
  ) {
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        // カメラセンサーは逆方向
        return DeviceOrientation.landscapeRight;
      case NativeDeviceOrientation.landscapeRight:
        // カメラセンサーは逆方向
        return DeviceOrientation.landscapeLeft;
      case NativeDeviceOrientation.portraitDown:
        return DeviceOrientation.portraitDown;
      case NativeDeviceOrientation.portraitUp:
      default:
        return DeviceOrientation.portraitUp;
    }
  }

  /// カメラのキャプチャ方向をロックする
  static Future<void> lockCaptureOrientation(
    CameraController controller,
    NativeDeviceOrientation orientation,
  ) async {
    final deviceOrientation = toDeviceOrientation(orientation);
    try {
      await controller.lockCaptureOrientation(deviceOrientation);
    } catch (e) {
      debugPrint('キャプチャ方向のロックに失敗: $e');
    }
  }

  /// UI要素の回転角度を取得する（四分の一回転の単位）
  static int getQuarterTurns(NativeDeviceOrientation orientation) {
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        return 3; // 270度時計回り
      case NativeDeviceOrientation.landscapeRight:
        return 1; // 90度時計回り
      case NativeDeviceOrientation.portraitDown:
        return 2; // 180度
      case NativeDeviceOrientation.portraitUp:
      default:
        return 0;
    }
  }
}
