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
  DateTime? _snapPauseTime;
  double? _lastSnapValue;

  final List<double> snapPoints;
  final double snapThreshold;
  final double snapSpeedThreshold;
  final int snapPauseDurationMs;

  ZoomController({
    this.snapPoints = AppConstants.zoomSnapPoints,
    this.snapThreshold = AppConstants.zoomSnapThreshold,
    this.snapSpeedThreshold = AppConstants.zoomSnapSpeedThreshold,
    this.snapPauseDurationMs = AppConstants.zoomSnapPauseDurationMs,
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

    // スナップ一時停止中の場合は更新しない
    if (_snapPauseTime != null && DateTime.now().isBefore(_snapPauseTime!)) {
      return ZoomUpdateResult.skip;
    }

    // 高速ドラッグ時はスナップをスキップ
    if (deltaDx.abs() > snapSpeedThreshold) {
      return ZoomUpdateResult(zoomLevel: newZoom);
    }

    // スナップポイントのチェック
    for (final point in snapPoints) {
      if ((newZoom - point).abs() < snapThreshold) {
        if (_lastSnapValue != point) {
          // スナップ発動：触覚フィードバック + 一時停止
          HapticFeedback.lightImpact();
          _snapPauseTime = DateTime.now().add(
            Duration(milliseconds: snapPauseDurationMs),
          );
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
    _snapPauseTime = null;
    _lastSnapValue = null;
  }
}
