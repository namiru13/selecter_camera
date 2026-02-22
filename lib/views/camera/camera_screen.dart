/// カメラ撮影画面
///
/// カメラプレビュー、録画ボタン、ズームゲージ、
/// プレビューボタン、グリッドライン、フォーカスインジケータ、
/// 録画タイマー、解像度設定、人物選択サイドバーを含むメイン撮影画面。
/// 画面はポートレートに固定し、UI要素のみデバイスの向きに
/// 合わせてアニメーション付きで回転する（一般的なスマホカメラと同じ挙動）。
library;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import '../../core/constants/app_constants.dart';
import '../../models/camera_state.dart';
import '../../viewmodels/camera_viewmodel.dart';
import '../../viewmodels/zoom_controller.dart';
import 'widgets/arc_zoom_gauge.dart';
import 'widgets/grid_overlay.dart';
import 'widgets/recording_timer.dart';
import 'widgets/video_preview_button.dart';
import 'widgets/person_selector_popup.dart';
import '../person/person_list_screen.dart';
import '../settings/settings_screen.dart';

/// カメラ撮影画面ウィジェット
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  final ZoomController _zoomController = ZoomController();

  /// ピンチズーム用の基準ズーム値
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// アプリのライフサイクル変更を処理する
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final viewModel = ref.read(cameraViewModelProvider.notifier);
    final cameraState = ref.read(cameraViewModelProvider);

    // カメラが初期化されていない場合は何もしない
    if (cameraState.status == CameraStatus.uninitialized ||
        cameraState.status == CameraStatus.error) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // カメラリソースを解放
        viewModel.disposeCamera();
        break;
      case AppLifecycleState.resumed:
        // カメラを再初期化
        viewModel.initializeCamera();
        break;
      default:
        break;
    }
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
    final isRecording = cameraState.status == CameraStatus.recording;

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
              if (isActive && !cameraState.isSaving)
                _buildCameraPreview(cameraState)
              else if (cameraState.isSaving)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('動画を処理中...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),

              // グリッドライン
              if (isActive && !cameraState.isSaving && cameraState.showGrid)
                const Positioned.fill(child: GridOverlay()),

              // フォーカスインジケータ
              if (isActive && cameraState.focusPoint != null)
                _buildFocusIndicator(cameraState.focusPoint!),

              // 録画タイマー
              if (isRecording && cameraState.recordingStartTime != null)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: RecordingTimer(
                      startTime: cameraState.recordingStartTime!,
                    ),
                  ),
                ),

              // ズームゲージ
              if (isActive && !cameraState.isSaving)
                _buildZoomGauge(cameraState, rotationTurns),

              // 録画ボタン
              if (!cameraState.isSaving) _buildRecordButton(cameraState),

              // プレビューボタン
              if (!cameraState.isSaving) _buildPreviewButton(cameraState),

              // 上部ツールバー（グリッド・設定）
              if (isActive && !isRecording && !cameraState.isSaving)
                _buildTopToolbar(cameraState),

              // 左上：人物一覧画面への遷移ボタン
              if (isActive && !isRecording && !cameraState.isSaving)
                Positioned(
                  top: 48,
                  left: 16,
                  child: _buildToolbarButton(
                    icon: Icons.people,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PersonListScreen(),
                        ),
                      );
                    },
                  ),
                ),

              // 左端：人物一覧リスト
              if (isActive && !cameraState.isSaving)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: orientation == NativeDeviceOrientation.landscapeLeft
                      ? 16
                      : (orientation == NativeDeviceOrientation.landscapeRight
                            ? null
                            : 100),
                  bottom: orientation == NativeDeviceOrientation.landscapeRight
                      ? 16
                      : (orientation == NativeDeviceOrientation.landscapeLeft
                            ? null
                            : 160),
                  left: orientation == NativeDeviceOrientation.landscapeLeft
                      ? 100
                      : (orientation == NativeDeviceOrientation.landscapeRight
                            ? 160
                            : 16),
                  right: orientation == NativeDeviceOrientation.landscapeLeft
                      ? 160
                      : (orientation == NativeDeviceOrientation.landscapeRight
                            ? 100
                            : null),
                  child: PersonListSideBar(
                    orientation: orientation,
                    rotationTurns: rotationTurns,
                  ),
                ),

              // 右上：選択された人物のポップアップ
              if (isActive && !cameraState.isSaving)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: orientation == NativeDeviceOrientation.landscapeLeft
                      ? null
                      : (orientation == NativeDeviceOrientation.landscapeRight
                            ? 72
                            : 48),
                  bottom: orientation == NativeDeviceOrientation.landscapeLeft
                      ? 72
                      : null,
                  left: orientation == NativeDeviceOrientation.landscapeRight
                      ? 48
                      : null,
                  right: orientation == NativeDeviceOrientation.landscapeLeft
                      ? 48
                      : (orientation == NativeDeviceOrientation.landscapeRight
                            ? null
                            : 72),
                  child: SelectedPersonsTopRight(rotationTurns: rotationTurns),
                ),

              // エラー表示
              if (cameraState.errorMessage != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "エラー: ${cameraState.errorMessage}",
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _initialize,
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// カメラプレビューウィジェット（ズーム・フォーカスジェスチャー付き）
  Widget _buildCameraPreview(CameraState cameraState) {
    return GestureDetector(
      // ピンチズーム
      onScaleStart: (details) {
        _baseZoom = cameraState.currentZoomLevel;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount >= 2) {
          // ピンチズーム
          final newZoom = _baseZoom * details.scale;
          ref.read(cameraViewModelProvider.notifier).setZoomLevel(newZoom);
        } else {
          // 水平スワイプズーム（1本指）
          _handleZoomDrag(
            DragUpdateDetails(
              globalPosition: details.focalPoint,
              delta: details.focalPointDelta,
            ),
            cameraState,
          );
        }
      },
      // タップでフォーカス
      onTapUp: (details) {
        _handleTapFocus(details, cameraState);
      },
      child: Center(child: CameraPreview(cameraState.controller!)),
    );
  }

  /// タップフォーカスを処理する
  void _handleTapFocus(TapUpDetails details, CameraState cameraState) {
    final screenSize = MediaQuery.of(context).size;
    final tapPosition = details.localPosition;

    // 画面座標を正規化座標（0.0〜1.0）に変換
    final normalizedPoint = Offset(
      tapPosition.dx / screenSize.width,
      tapPosition.dy / screenSize.height,
    );

    ref.read(cameraViewModelProvider.notifier).setFocusPoint(normalizedPoint);
  }

  /// フォーカスインジケータを描画する
  Widget _buildFocusIndicator(Offset focusPoint) {
    final screenSize = MediaQuery.of(context).size;
    return Positioned(
      left: focusPoint.dx * screenSize.width - 30,
      top: focusPoint.dy * screenSize.height - 30,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
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
              onPressed: () async {
                if (isRecording) {
                  await ref
                      .read(cameraViewModelProvider.notifier)
                      .stopRecording();

                  if (!mounted) return;
                  final currentState = ref.read(cameraViewModelProvider);

                  // エラーがなく、設定がONの場合に確認ダイアログを表示
                  if (currentState.status != CameraStatus.error) {
                    if (currentState.showPersonSelectionConfirmation) {
                      _showPersonSelectionDialog(context);
                    } else {
                      // 確認なしの場合はすぐに保存処理へ移行
                      ref
                          .read(cameraViewModelProvider.notifier)
                          .processAndSaveVideo();
                    }
                  }
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

  /// 上部ツールバー（設定画面への遷移）
  Widget _buildTopToolbar(CameraState cameraState) {
    return Positioned(
      top: 48,
      right: 16,
      child: Column(
        children: [
          // 設定ボタン
          _buildToolbarButton(
            icon: Icons.settings,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  /// 録画終了後の人物確認ダイアログを表示する
  void _showPersonSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 外側タップで閉じさせない
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('滑走者の確認', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '撮影した滑走者を選択してください',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 300,
                child: PersonListSideBar(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // 選択完了後、ビデオ保存処理を開始
                ref
                    .read(cameraViewModelProvider.notifier)
                    .processAndSaveVideo();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
