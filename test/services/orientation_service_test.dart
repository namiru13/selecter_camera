import 'package:flutter_test/flutter_test.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:selecter_camera/services/orientation_service.dart';
import 'package:flutter/services.dart';

void main() {
  group('OrientationService', () {
    group('toDeviceOrientation - NativeからFlutterへの向き変換', () {
      test('portraitUpはDeviceOrientation.portraitUpに変換される', () {
        final result = OrientationService.toDeviceOrientation(
          NativeDeviceOrientation.portraitUp,
        );
        expect(result, DeviceOrientation.portraitUp);
      });

      test('portraitDownはDeviceOrientation.portraitDownに変換される', () {
        final result = OrientationService.toDeviceOrientation(
          NativeDeviceOrientation.portraitDown,
        );
        expect(result, DeviceOrientation.portraitDown);
      });

      test('landscapeLeftはDeviceOrientation.landscapeRight（反転）に変換される', () {
        final result = OrientationService.toDeviceOrientation(
          NativeDeviceOrientation.landscapeLeft,
        );
        // カメラセンサーの向きが逆のため反転
        expect(result, DeviceOrientation.landscapeRight);
      });

      test('landscapeRightはDeviceOrientation.landscapeLeft（反転）に変換される', () {
        final result = OrientationService.toDeviceOrientation(
          NativeDeviceOrientation.landscapeRight,
        );
        // カメラセンサーの向きが逆のため反転
        expect(result, DeviceOrientation.landscapeLeft);
      });
    });

    group('getQuarterTurns - UI回転角度の取得', () {
      test('portraitUpは0を返す', () {
        expect(
          OrientationService.getQuarterTurns(
            NativeDeviceOrientation.portraitUp,
          ),
          0,
        );
      });

      test('landscapeRightは1を返す（90度）', () {
        expect(
          OrientationService.getQuarterTurns(
            NativeDeviceOrientation.landscapeRight,
          ),
          1,
        );
      });

      test('portraitDownは2を返す（180度）', () {
        expect(
          OrientationService.getQuarterTurns(
            NativeDeviceOrientation.portraitDown,
          ),
          2,
        );
      });

      test('landscapeLeftは3を返す（270度）', () {
        expect(
          OrientationService.getQuarterTurns(
            NativeDeviceOrientation.landscapeLeft,
          ),
          3,
        );
      });
    });
  });
}
