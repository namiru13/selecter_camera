/// アプリケーション全体で使用する定数
///
/// マジックナンバーを排除し、一元管理するための定数クラス。
class AppConstants {
  // === AI推論関連 ===
  /// 検出の閾値
  static const double detectionThreshold = 0.8;

  /// 推論の間引きフレーム数（30FPSの場合、約3FPS相当）
  static const int inferenceIntervalFrames = 10;

  /// サムネイル動画の秒数
  static const double thumbnailDuration = 0.1;

  // === ズーム関連 ===
  /// ズームのスナップポイント（x倍）
  static const List<double> zoomSnapPoints = [2.0, 3.0, 6.0, 10.0];

  /// スナップ判定の閾値（ズーム値の差がこの値以下ならスナップ）
  static const double zoomSnapThreshold = 0.2;

  /// スナップをスキップするドラッグ速度の閾値
  static const double zoomSnapSpeedThreshold = 3.0;

  /// スナップ時の一時停止時間（ミリ秒）
  static const int zoomSnapPauseDurationMs = 100;

  // === UI レイアウト ===
  /// 録画ボタンのサイズ
  static const double recordButtonSize = 64.0;

  /// 録画ボタンの底部パディング
  static const double recordButtonBottomPadding = 10.0;

  /// ズームゲージの底部パディング
  static const double zoomGaugeBottomPadding = 80.0;

  /// プレビューボタンのパディング
  static const double previewButtonPadding = 16.0;

  /// プレビューボタンのサイズ
  static const double previewButtonSize = 80.0;

  // === アークズームゲージ ===
  /// ゲージの高さ
  static const double gaugeHeight = 80.0;

  /// 可視角度（度）
  static const double gaugeVisibleAngleDeg = 100.0;

  /// ズーム1単位あたりの角度（度）
  static const double gaugeAnglePerUnitDeg = 22.0;

  /// アーク背景の不透明度
  static const double gaugeArcAlpha = 0.2;

  /// アーク背景の線幅
  static const double gaugeArcStrokeWidth = 40.0;

  /// ズームテキストのフォントサイズ
  static const double gaugeZoomFontSize = 24.0;

  /// ティックラベルのフォントサイズ
  static const double gaugeTickLabelFontSize = 12.0;
}
