@GenerateNiceMocks([MockSpec<CameraService>(), MockSpec<CameraController>()])
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:selecter_camera/models/camera_state.dart';
import 'package:selecter_camera/services/camera_service.dart';
import 'package:selecter_camera/services/settings_service.dart';
import 'package:selecter_camera/viewmodels/camera_viewmodel.dart';

import 'camera_viewmodel_test.mocks.dart';

/// テスト用のSettingsServiceスタブ
///
/// SharedPreferencesに依存しない固定値を返す。
class FakeSettingsService extends SettingsService {
  @override
  Future<ResolutionPreset> getResolutionPreset() async => ResolutionPreset.high;

  @override
  Future<bool> getShowGrid() async => false;

  @override
  Future<void> setResolutionPreset(ResolutionPreset preset) async {}

  @override
  Future<void> setShowGrid(bool show) async {}

  @override
  Future<ConfirmPersonSelectionMode> getConfirmPersonSelectionMode() async =>
      ConfirmPersonSelectionMode.always;

  @override
  Future<void> setConfirmPersonSelectionMode(
    ConfirmPersonSelectionMode mode,
  ) async {}

  @override
  Future<ExposureAdjustmentMode> getExposureAdjustmentMode() async =>
      ExposureAdjustmentMode.off;

  @override
  Future<void> setExposureAdjustmentMode(ExposureAdjustmentMode mode) async {}

  @override
  Future<double> getExposureOffset() async => 0.0;

  @override
  Future<void> setExposureOffset(double offset) async {}
}

void main() {
  late MockCameraService mockCameraService;
  late MockCameraController mockCameraController;
  late ProviderContainer container;

  setUp(() {
    mockCameraService = MockCameraService();
    mockCameraController = MockCameraController();

    // CameraControllerの初期状態を設定
    when(mockCameraController.value).thenReturn(
      const CameraValue(
        isInitialized: true,
        isRecordingVideo: false,
        isRecordingPaused: false,
        isStreamingImages: false,
        isTakingPicture: false,
        flashMode: FlashMode.off,
        exposureMode: ExposureMode.auto,
        exposurePointSupported: true,
        focusMode: FocusMode.auto,
        focusPointSupported: true,
        deviceOrientation: DeviceOrientation.portraitUp,
        lockedCaptureOrientation: DeviceOrientation.portraitUp,
        recordingOrientation: DeviceOrientation.portraitUp,
        previewSize: Size(1080, 1920),
        errorDescription: null,
        description: CameraDescription(
          name: '0',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ),
    );

    // ズーム範囲のモック
    when(mockCameraController.getMinZoomLevel()).thenAnswer((_) async => 1.0);
    when(mockCameraController.getMaxZoomLevel()).thenAnswer((_) async => 8.0);
    when(mockCameraController.setZoomLevel(any)).thenAnswer((_) async {});

    // 露出調整のモック
    when(
      mockCameraController.getMinExposureOffset(),
    ).thenAnswer((_) async => -2.0);
    when(
      mockCameraController.getMaxExposureOffset(),
    ).thenAnswer((_) async => 2.0);
    when(
      mockCameraController.getExposureOffsetStepSize(),
    ).thenAnswer((_) async => 0.5);
    when(
      mockCameraController.setExposureOffset(any),
    ).thenAnswer((_) async => 0.0);

    // CameraServiceがモックコントローラーを返すように設定
    when(mockCameraService.controller).thenReturn(mockCameraController);
    when(
      mockCameraService.initialize(
        resolutionPreset: anyNamed('resolutionPreset'),
        lensDirection: anyNamed('lensDirection'),
      ),
    ).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        cameraServiceProvider.overrideWithValue(mockCameraService),
        settingsServiceProvider.overrideWithValue(FakeSettingsService()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CameraViewModel', () {
    test('initializeCamera sets default zoom to 1.0', () async {
      // 範囲: 0.5 ~ 8.0 (1.0を含む)
      when(mockCameraController.getMinZoomLevel()).thenAnswer((_) async => 0.5);
      when(mockCameraController.getMaxZoomLevel()).thenAnswer((_) async => 8.0);

      final viewModel = container.read(cameraViewModelProvider.notifier);
      await viewModel.initializeCamera();

      final state = container.read(cameraViewModelProvider);

      // 状態が更新されていること
      expect(state.currentZoomLevel, 1.0);

      // 実機に反映されていること
      verify(mockCameraController.setZoomLevel(1.0)).called(1);
    });

    test(
      'initializeCamera clamps default zoom to minZoom if min > 1.0',
      () async {
        // 範囲: 2.0 ~ 8.0 (1.0を含まない)
        when(
          mockCameraController.getMinZoomLevel(),
        ).thenAnswer((_) async => 2.0);
        when(
          mockCameraController.getMaxZoomLevel(),
        ).thenAnswer((_) async => 8.0);

        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.initializeCamera();

        final state = container.read(cameraViewModelProvider);

        // minZoomにクランプされること
        expect(state.currentZoomLevel, 2.0);

        // 実機に反映されていること
        verify(mockCameraController.setZoomLevel(2.0)).called(1);
      },
    );

    test(
      'initializeCamera clamps default zoom to maxZoom if max < 1.0',
      () async {
        // 異常系だが念のため: 0.1 ~ 0.5 (1.0を含まない)
        when(
          mockCameraController.getMinZoomLevel(),
        ).thenAnswer((_) async => 0.1);
        when(
          mockCameraController.getMaxZoomLevel(),
        ).thenAnswer((_) async => 0.5);

        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.initializeCamera();

        final state = container.read(cameraViewModelProvider);

        // maxZoomにクランプされること
        expect(state.currentZoomLevel, 0.5);

        // 実機に反映されていること
        verify(mockCameraController.setZoomLevel(0.5)).called(1);
      },
    );

    test('setExposureAdjustmentMode updates state and controller', () async {
      final viewModel = container.read(cameraViewModelProvider.notifier);
      await viewModel.initializeCamera();

      // 手動モードに変更
      await viewModel.setExposureAdjustmentMode(ExposureAdjustmentMode.manual);
      expect(
        container.read(cameraViewModelProvider).exposureAdjustmentMode,
        ExposureAdjustmentMode.manual,
      );

      // OFFに戻す（オフセットがリセットされること）
      await viewModel.setExposureAdjustmentMode(ExposureAdjustmentMode.off);
      expect(
        container.read(cameraViewModelProvider).exposureAdjustmentMode,
        ExposureAdjustmentMode.off,
      );
      expect(container.read(cameraViewModelProvider).exposureOffset, 0.0);
      verify(
        mockCameraController.setExposureOffset(0.0),
      ).called(3); // 初期化時 + モード戻し時
    });

    test('setExposureOffset updates state and controller', () async {
      final viewModel = container.read(cameraViewModelProvider.notifier);
      await viewModel.initializeCamera();

      await viewModel.setExposureOffset(1.5);
      expect(container.read(cameraViewModelProvider).exposureOffset, 1.5);
      verify(mockCameraController.setExposureOffset(1.5)).called(1);
    });

    test('setExposureOffset clamps value to min/max', () async {
      final viewModel = container.read(cameraViewModelProvider.notifier);
      await viewModel.initializeCamera();

      // max (2.0) を超える値を設定
      await viewModel.setExposureOffset(5.0);
      expect(container.read(cameraViewModelProvider).exposureOffset, 2.0);
      verify(mockCameraController.setExposureOffset(2.0)).called(1);

      // min (-2.0) を下回る値を設定
      await viewModel.setExposureOffset(-5.0);
      expect(container.read(cameraViewModelProvider).exposureOffset, -2.0);
      verify(mockCameraController.setExposureOffset(-2.0)).called(1);
    });
  });
}
