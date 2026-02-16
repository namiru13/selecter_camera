import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../viewmodels/camera_viewmodel.dart';
import 'widgets/arc_zoom_gauge.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  DateTime? _snapPauseTime;
  double? _lastSnapValue;
  final List<double> _snapPoints = [2.0, 3.0, 6.0, 10.0];
  final double _snapThreshold = 0.2;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await ref.read(cameraViewModelProvider.notifier).initializeCamera();
    // Start inference loop after initialization (optional: can be triggered by a button or state)
    // ref.read(cameraViewModelProvider.notifier).startInferenceLoop();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraViewModelProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          if (cameraState.status == CameraStatus.ready ||
              cameraState.status == CameraStatus.recording)
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Padding left: 32, right: 32 -> total 64 subtraction
                final barWidth = screenWidth - 64.0;
                final zoomRange =
                    cameraState.maxZoomLevel - cameraState.minZoomLevel;

                if (barWidth > 0 && zoomRange > 0) {
                  // Calculate raw new zoom level based on drag
                  double newZoom =
                      cameraState.currentZoomLevel -
                      (details.delta.dx / barWidth) * zoomRange;

                  // Snap Logic

                  // Check if we are currently paused
                  if (_snapPauseTime != null &&
                      DateTime.now().isBefore(_snapPauseTime!)) {
                    return; // Pause updates
                  }

                  // Check for snap points
                  for (final point in _snapPoints) {
                    if ((newZoom - point).abs() < _snapThreshold) {
                      // Found a snap point candidate
                      if (_lastSnapValue != point) {
                        // Start snapping
                        HapticFeedback.lightImpact();
                        _snapPauseTime = DateTime.now().add(
                          const Duration(milliseconds: 100),
                        );
                        _lastSnapValue = point;
                        ref
                            .read(cameraViewModelProvider.notifier)
                            .setZoomLevel(point);
                        return; // Stop update for this frame
                      }
                    }
                  }

                  // Reset last snap value if we are far enough from all points
                  bool closeToAnyPoint = _snapPoints.any(
                    (p) => (newZoom - p).abs() < _snapThreshold,
                  );
                  if (!closeToAnyPoint) {
                    _lastSnapValue = null;
                  }

                  // Apply zoom if not paused
                  ref
                      .read(cameraViewModelProvider.notifier)
                      .setZoomLevel(newZoom);
                }
              },
              child: SizedBox.expand(
                child: CameraPreview(cameraState.controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Zoom Indicator (Arc Dial)
          if (cameraState.status == CameraStatus.ready ||
              cameraState.status == CameraStatus.recording)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 110.0),
                child: ArcZoomGauge(
                  currentZoom: cameraState.currentZoomLevel,
                  minZoom: cameraState.minZoomLevel,
                  maxZoom: cameraState.maxZoomLevel,
                  snapPoints: _snapPoints,
                ),
              ),
            ),

          // Recording Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FittedBox(
                  child: FloatingActionButton.large(
                    backgroundColor:
                        cameraState.status == CameraStatus.recording
                        ? Colors.red
                        : Colors.white,
                    onPressed: () {
                      if (cameraState.status == CameraStatus.recording) {
                        ref
                            .read(cameraViewModelProvider.notifier)
                            .stopRecording();
                      } else {
                        ref
                            .read(cameraViewModelProvider.notifier)
                            .startRecording();
                      }
                    },
                    child: Icon(
                      cameraState.status == CameraStatus.recording
                          ? Icons.stop
                          : Icons.fiber_manual_record,
                      color: cameraState.status == CameraStatus.recording
                          ? Colors.white
                          : Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Debug Overlay
          if (cameraState.errorMessage != null)
            Center(
              child: Text(
                "Error: ${cameraState.errorMessage}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
