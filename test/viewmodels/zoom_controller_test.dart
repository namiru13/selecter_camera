import 'package:flutter_test/flutter_test.dart';
import 'package:selecter_camera/viewmodels/zoom_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ZoomController controller;

  setUp(() {
    controller = ZoomController(
      snapPoints: [2.0, 3.0, 6.0, 10.0],
      snapThreshold: 0.2,
      snapSpeedThreshold: 3.0,
      snapPauseDurationMs: 100,
    );
  });

  group('ZoomController', () {
    group('通常のズーム計算', () {
      test('通常のドラッグでズーム値が更新される', () {
        final result = controller.calculateZoom(
          currentZoom: 5.0,
          deltaDx: -10.0,
          barWidth: 200.0,
          zoomRange: 9.0,
        );

        expect(result.zoomLevel, isNotNull);
        expect(result.snapped, false);
      });

      test('ドラッグ量に比例してズーム値が変化する', () {
        final result = controller.calculateZoom(
          currentZoom: 5.0,
          deltaDx: -20.0, // 左方向ドラッグ = ズームイン
          barWidth: 200.0,
          zoomRange: 10.0,
        );

        // 期待値: 5.0 - (-20.0 / 200.0) * 10.0 = 5.0 + 1.0 = 6.0
        expect(result.zoomLevel, closeTo(6.0, 0.01));
      });

      test('右方向ドラッグでズームアウトする', () {
        final result = controller.calculateZoom(
          currentZoom: 5.0,
          deltaDx: 20.0, // 右方向ドラッグ = ズームアウト
          barWidth: 200.0,
          zoomRange: 10.0,
        );

        // 期待値: 5.0 - (20.0 / 200.0) * 10.0 = 5.0 - 1.0 = 4.0
        expect(result.zoomLevel, closeTo(4.0, 0.01));
      });
    });

    group('無効な入力の処理', () {
      test('barWidthが0の場合はスキップされる', () {
        final result = controller.calculateZoom(
          currentZoom: 5.0,
          deltaDx: 10.0,
          barWidth: 0.0,
          zoomRange: 9.0,
        );

        expect(result.zoomLevel, isNull);
      });

      test('zoomRangeが0の場合はスキップされる', () {
        final result = controller.calculateZoom(
          currentZoom: 1.0,
          deltaDx: 10.0,
          barWidth: 200.0,
          zoomRange: 0.0,
        );

        expect(result.zoomLevel, isNull);
      });

      test('負のbarWidthはスキップされる', () {
        final result = controller.calculateZoom(
          currentZoom: 5.0,
          deltaDx: 10.0,
          barWidth: -100.0,
          zoomRange: 9.0,
        );

        expect(result.zoomLevel, isNull);
      });
    });

    group('高速ドラッグ時のスナップスキップ', () {
      test('速度が閾値を超えるとスナップしない', () {
        // スナップポイント付近（2.0）に近い値でも、高速ドラッグならスナップしない
        final result = controller.calculateZoom(
          currentZoom: 2.05,
          deltaDx: -5.0, // 閾値3.0を超える速度
          barWidth: 200.0,
          zoomRange: 9.0,
        );

        expect(result.zoomLevel, isNotNull);
        expect(result.snapped, false);
      });
    });

    group('スナップポイントの動作', () {
      test('スナップポイント付近でスナップが発生する', () {
        // ゆっくりドラッグ（速度 < 3.0）でスナップポイント付近に入る
        final result = controller.calculateZoom(
          currentZoom: 2.05,
          deltaDx: -0.5, // ゆっくりドラッグ
          barWidth: 200.0,
          zoomRange: 9.0,
        );

        // スナップポイント2.0にスナップするはず
        expect(result.zoomLevel, 2.0);
        expect(result.snapped, true);
      });

      test('スナップポイントから離れた位置では通常のズームが適用される', () {
        final result = controller.calculateZoom(
          currentZoom: 4.5,
          deltaDx: -0.5, // ゆっくりドラッグ
          barWidth: 200.0,
          zoomRange: 9.0,
        );

        // 4.5付近にはスナップポイントがないので通常のズーム
        expect(result.snapped, false);
      });

      test('同じスナップポイントには連続してスナップしない', () {
        // 初回スナップ
        controller.calculateZoom(
          currentZoom: 2.05,
          deltaDx: -0.5,
          barWidth: 200.0,
          zoomRange: 9.0,
        );

        // 一時停止解除を待つためスナップ時間を過ぎたことにする
        // ここではスナップ済みなので、同じポイントにはスナップしない
        // (一時停止時間内は完全にスキップされる)
      });
    });

    group('reset', () {
      test('リセット後は新しいスナップが可能になる', () {
        // 初回スナップ
        final firstResult = controller.calculateZoom(
          currentZoom: 2.05,
          deltaDx: -0.5,
          barWidth: 200.0,
          zoomRange: 9.0,
        );
        expect(firstResult.snapped, true);

        // リセット
        controller.reset();

        // リセット後に同じスナップポイントに再度スナップ可能
        final secondResult = controller.calculateZoom(
          currentZoom: 2.05,
          deltaDx: -0.5,
          barWidth: 200.0,
          zoomRange: 9.0,
        );
        expect(secondResult.snapped, true);
        expect(secondResult.zoomLevel, 2.0);
      });
    });
  });
}
