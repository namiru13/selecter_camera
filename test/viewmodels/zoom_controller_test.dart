import 'package:flutter_test/flutter_test.dart';
import 'package:selecter_camera/viewmodels/zoom_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ZoomController controller;

  setUp(() {
    controller = ZoomController(
      snapPoints: [2.0, 3.0, 6.0, 10.0],
      snapThreshold: 0.2,
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

    group('スナップポイントの動作', () {
      test('スナップポイント付近でスナップが発生する', () {
        final result = controller.calculateZoom(
          currentZoom: 2.05,
          deltaDx: -0.5,
          barWidth: 200.0,
          zoomRange: 9.0,
        );

        // スナップポイント2.0にスナップするはず
        expect(result.zoomLevel, 2.0);
        expect(result.snapped, true);
      });

      test('高速ドラッグ時でもスナップが発生する（機能削除の確認）', () {
        // 現在の計算式: 2.05 - (-10.0 / 200.0) * 9.0 = 2.05 + 0.45 = 2.5
        final result = controller.calculateZoom(
          currentZoom: 2.05,
          deltaDx: -10.0, // 高速ドラッグ
          barWidth: 200.0,
          zoomRange: 9.0,
        );

        // 2.5x付近にはスナップポイントがないため、そのままの計算結果が返るはず
        expect(result.zoomLevel, closeTo(2.5, 0.01));
        expect(result.snapped, false);
      });

      test('スナップポイントから離れた位置では通常のズームが適用される', () {
        final result = controller.calculateZoom(
          currentZoom: 4.5,
          deltaDx: -0.5,
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

        // 次の移動で、まだスナップ範囲内でも snapped は false になるはず
        final result = controller.calculateZoom(
          currentZoom: 2.0,
          deltaDx: -0.1,
          barWidth: 200.0,
          zoomRange: 9.0,
        );
        expect(result.snapped, false);
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
