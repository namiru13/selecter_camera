/// カメラ撮影画面
///
/// カメラプレビュー、録画ボタン、ズームゲージ、
/// プレビューボタンを含むメイン撮影画面。
/// 画面はポートレートに固定し、UI要素のみデバイスの向きに
/// 合わせてアニメーション付きで回転する（一般的なスマホカメラと同じ挙動）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import '../../core/constants/app_constants.dart';
import '../../models/camera_state.dart';
import '../../viewmodels/camera_viewmodel.dart';
import '../../viewmodels/zoom_controller.dart';
import 'widgets/arc_zoom_gauge.dart';
import 'widgets/video_preview_button.dart';

/// カメラ撮影画面ウィジェット
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ZoomController _zoomController = ZoomController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await ref.read(cameraViewModelProvider.notifier).initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraViewModelProvider);
    final isActive =
        cameraState.status == CameraStatus.ready ||
        cameraState.status == CameraStatus.recording;

    return NativeDeviceOrientationReader(
      builder: (context) {
        final orientation = NativeDeviceOrientationReader.orientation(context);
        double rotationTurns = 0.0;
        switch (orientation) {
          case NativeDeviceOrientation.landscapeLeft:
            rotationTurns = 0.25;
            break;
          case NativeDeviceOrientation.landscapeRight:
            rotationTurns = -0.25;
            break;
          case NativeDeviceOrientation.portraitDown:
            rotationTurns = 0.5;
            break;
          default:
            rotationTurns = 0.0;
            break;
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // カメラプレビュー（回転なし・常にフルスクリーン）
              if (isActive)
                _buildCameraPreview(cameraState)
              else
                const Center(child: CircularProgressIndicator()),

              // ズームゲージ
              if (isActive) _buildZoomGauge(cameraState, rotationTurns),

              // 録画ボタン
              _buildRecordButton(cameraState),

              // プレビューボタン
              _buildPreviewButton(cameraState),

              // エラー表示
              if (cameraState.errorMessage != null)
                Center(
                  child: Text(
                    "エラー: ${cameraState.errorMessage}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// カメラプレビューウィジェット（ズームジェスチャー付き）
  ///
  /// プレビューは回転させず、常にフルスクリーンで表示する。
  /// （一般的なスマホカメラと同じ挙動）
  Widget _buildCameraPreview(CameraState cameraState) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) =>
          _handleZoomDrag(details, cameraState),
      child: Center(child: CameraPreview(cameraState.controller!)),
    );
  }

  /// ズームドラッグを処理する
  void _handleZoomDrag(DragUpdateDetails details, CameraState cameraState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth - (AppConstants.previewButtonPadding * 4);
    final zoomRange = cameraState.maxZoomLevel - cameraState.minZoomLevel;

    final result = _zoomController.calculateZoom(
      currentZoom: cameraState.currentZoomLevel,
      deltaDx: details.delta.dx,
      barWidth: barWidth,
      zoomRange: zoomRange,
    );

    if (result.zoomLevel != null) {
      ref
          .read(cameraViewModelProvider.notifier)
          .setZoomLevel(result.zoomLevel!);
    }
  }

  /// ズームゲージウィジェット
  Widget _buildZoomGauge(CameraState cameraState, double rotationTurns) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppConstants.zoomGaugeBottomPadding,
        ),
        child: ArcZoomGauge(
          currentZoom: cameraState.currentZoomLevel,
          minZoom: cameraState.minZoomLevel,
          maxZoom: cameraState.maxZoomLevel,
          snapPoints: AppConstants.zoomSnapPoints,
          rotationTurns: rotationTurns,
        ),
      ),
    );
  }

  /// 録画ボタンウィジェット
  Widget _buildRecordButton(CameraState cameraState) {
    final isRecording = cameraState.status == CameraStatus.recording;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppConstants.recordButtonBottomPadding,
        ),
        child: SizedBox(
          width: AppConstants.recordButtonSize,
          height: AppConstants.recordButtonSize,
          child: FittedBox(
            child: FloatingActionButton.large(
              backgroundColor: isRecording ? Colors.red : Colors.white,
              onPressed: () {
                if (isRecording) {
                  ref.read(cameraViewModelProvider.notifier).stopRecording();
                } else {
                  ref.read(cameraViewModelProvider.notifier).startRecording();
                }
              },
              child: Icon(
                isRecording ? Icons.stop : Icons.fiber_manual_record,
                color: isRecording ? Colors.white : Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// プレビューボタンウィジェット
  Widget _buildPreviewButton(CameraState cameraState) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.previewButtonPadding),
        child: VideoPreviewButton(videoPath: cameraState.lastVideoPath),
      ),
    );
  }
}
