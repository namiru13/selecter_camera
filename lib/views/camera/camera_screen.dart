/// カメラ撮影画面
///
/// カメラプレビュー、録画ボタン、ズームゲージ、
/// プレビューボタンを含むメイン撮影画面。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../core/constants/app_constants.dart';
import '../../models/camera_state.dart';
import '../../viewmodels/camera_viewmodel.dart';
import '../../viewmodels/zoom_controller.dart';
import '../../services/orientation_service.dart';
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
    final quarterTurns = OrientationService.getQuarterTurns(
      cameraState.sensorOrientation,
    );

    return Scaffold(
      body: Stack(
        children: [
          // カメラプレビュー
          if (isActive)
            _buildCameraPreview(cameraState, quarterTurns)
          else
            const Center(child: CircularProgressIndicator()),

          // ズームゲージ
          if (isActive) _buildZoomGauge(cameraState),

          // 録画ボタン
          _buildRecordButton(cameraState, quarterTurns),

          // プレビューボタン
          _buildPreviewButton(cameraState, quarterTurns),

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
  }

  /// カメラプレビューウィジェット（ズームジェスチャー付き）
  Widget _buildCameraPreview(CameraState cameraState, int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) =>
            _handleZoomDrag(details, cameraState),
        child: SizedBox.expand(child: CameraPreview(cameraState.controller!)),
      ),
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
  Widget _buildZoomGauge(CameraState cameraState) {
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
        ),
      ),
    );
  }

  /// 録画ボタンウィジェット
  Widget _buildRecordButton(CameraState cameraState, int quarterTurns) {
    final isRecording = cameraState.status == CameraStatus.recording;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppConstants.recordButtonBottomPadding,
        ),
        child: RotatedBox(
          quarterTurns: quarterTurns,
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
      ),
    );
  }

  /// プレビューボタンウィジェット
  Widget _buildPreviewButton(CameraState cameraState, int quarterTurns) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.previewButtonPadding),
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: VideoPreviewButton(videoPath: cameraState.lastVideoPath),
        ),
      ),
    );
  }
}
