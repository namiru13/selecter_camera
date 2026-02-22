/// ズーム制御ロジック
///
/// スナップポイント判定、速度による制御など、
/// カメラのズームに関するビジネスロジックを集約する。
library;

import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

/// ズーム制御の結果を表すクラス
class ZoomUpdateResult {
  /// 適用すべきズーム値（nullの場合は更新しない）
  final double? zoomLevel;

  /// スナップが発生したかどうか
  final bool snapped;

  const ZoomUpdateResult({this.zoomLevel, this.snapped = false});

  /// 更新なし（一時停止中など）
  static const skip = ZoomUpdateResult();
}

/// ズームのスナップロジックを管理するコントローラー
class ZoomController {
  DateTime? _lastHapticTime;
  double? _lastSnapValue;

  final List<double> snapPoints;
  final double snapThreshold;

  ZoomController({
    this.snapPoints = AppConstants.zoomSnapPoints,
    this.snapThreshold = AppConstants.zoomSnapThreshold,
  });

  /// ドラッグ入力からズーム値を計算する
  ///
  /// [currentZoom] 現在のズームレベル
  /// [deltaDx] ドラッグの水平方向の移動量
  /// [barWidth] ズームバーの幅
  /// [zoomRange] ズームの範囲（max - min）
  ///
  /// 戻り値: 適用すべきズーム値を含む [ZoomUpdateResult]
  ZoomUpdateResult calculateZoom({
    required double currentZoom,
    required double deltaDx,
    required double barWidth,
    required double zoomRange,
  }) {
    if (barWidth <= 0 || zoomRange <= 0) {
      return ZoomUpdateResult.skip;
    }

    // ドラッグ量からズーム値を計算
    final newZoom = currentZoom - (deltaDx / barWidth) * zoomRange;

    // スナップポイントのチェック
    for (final point in snapPoints) {
      if ((newZoom - point).abs() < snapThreshold) {
        if (_lastSnapValue != point) {
          // スナップ発動：触覚フィードバック
          // 短時間に連続して振動させないためのガード（オプション、必要なら）
          final now = DateTime.now();
          if (_lastHapticTime == null ||
              now.difference(_lastHapticTime!).inMilliseconds > 50) {
            HapticFeedback.lightImpact();
            _lastHapticTime = now;
          }
          _lastSnapValue = point;
          return ZoomUpdateResult(zoomLevel: point, snapped: true);
        }
      }
    }

    // スナップポイントから離れたらリセット
    final closeToAnyPoint = snapPoints.any(
      (p) => (newZoom - p).abs() < snapThreshold,
    );
    if (!closeToAnyPoint) {
      _lastSnapValue = null;
    }

    return ZoomUpdateResult(zoomLevel: newZoom);
  }

  /// スナップ状態をリセットする
  void reset() {
    _lastHapticTime = null;
    _lastSnapValue = null;
  }
}
