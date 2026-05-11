import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

/// センサーデータ（Roll, Pitch）を保持するモデル
class SensorData {
  final double roll; // 左右の傾き (radian)
  final double pitch; // 前後の傾き (radian)

  SensorData({required this.roll, required this.pitch});

  factory SensorData.zero() => SensorData(roll: 0, pitch: 0);

  bool get isLevel {
    // ±2度以内を水平とみなす
    const threshold = 2.0 * math.pi / 180.0;

    // 目標角度 (0, 90, 180, -90, -180 度)
    final targetAngles = [0.0, math.pi / 2, math.pi, -math.pi / 2, -math.pi];

    // roll と各目標位置での理想角度との差の最小値を求める
    double minDiff = double.infinity;
    for (var angle in targetAngles) {
      final diff = (roll - angle).abs();
      if (diff < minDiff) {
        minDiff = diff;
      }
    }

    return minDiff < threshold;
  }
}

/// センサーデータの取得とフィルタリングを行うサービス
class SensorService {
  final ValueNotifier<SensorData> sensorData = ValueNotifier(SensorData.zero());
  StreamSubscription<AccelerometerEvent>? _subscription;

  // ローパスフィルタの係数 (0.0 < alpha < 1.0)
  // 小さいほど滑らかになるが、遅延が増える
  static const double _alpha = 0.1;

  double _filteredX = 0;
  double _filteredY = 0;
  double _filteredZ = 9.8; // 重力加速度の初期値

  void start() {
    _subscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      _updateValues(event.x, event.y, event.z);
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// リソースを解放する
  void dispose() {
    stop();
    sensorData.dispose();
  }

  void _updateValues(double x, double y, double z) {
    // ローパスフィルタの適用
    _filteredX = _alpha * x + (1 - _alpha) * _filteredX;
    _filteredY = _alpha * y + (1 - _alpha) * _filteredY;
    _filteredZ = _alpha * z + (1 - _alpha) * _filteredZ;

    // Roll/Pitch の計算
    // デバイスの向き（Portrait/Landscape）によって軸の解釈が変わる可能性があるが、
    // ここでは標準的な加速度ベクトルからの傾斜計算を行う。
    // Roll: 左右の傾き (X-Y平面)
    // Pitch: 前後の傾き (Z軸方向)

    // 加速度センサーのみを使用する場合の計算式
    final double roll = math.atan2(_filteredX, _filteredY);
    final double pitch = math.atan2(
      -_filteredZ,
      math.sqrt(_filteredX * _filteredX + _filteredY * _filteredY),
    );

    sensorData.value = SensorData(roll: roll, pitch: pitch);
  }
}
