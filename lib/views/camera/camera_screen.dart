import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../viewmodels/camera_viewmodel.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
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
                final sensitivity = 0.01;
                final newZoom =
                    cameraState.currentZoomLevel +
                    (details.delta.dx * sensitivity);
                ref
                    .read(cameraViewModelProvider.notifier)
                    .setZoomLevel(newZoom);
              },
              child: SizedBox.expand(
                child: CameraPreview(cameraState.controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Zoom Indicator (Horizontal Bar above Recording Button)
          if (cameraState.status == CameraStatus.ready ||
              cameraState.status == CameraStatus.recording)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 120.0,
                  left: 32,
                  right: 32,
                ),
                child: Container(
                  height: 30,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final range =
                              cameraState.maxZoomLevel -
                              cameraState.minZoomLevel;
                          if (range <= 0) return const SizedBox();

                          final percent =
                              (cameraState.currentZoomLevel -
                                  cameraState.minZoomLevel) /
                              range;

                          return Container(
                            width: constraints.maxWidth * percent,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          );
                        },
                      ),
                      Center(
                        child: Text(
                          "${cameraState.currentZoomLevel.toStringAsFixed(1)}x",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Recording Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FloatingActionButton.large(
                backgroundColor: cameraState.status == CameraStatus.recording
                    ? Colors.red
                    : Colors.white,
                onPressed: () {
                  if (cameraState.status == CameraStatus.recording) {
                    ref.read(cameraViewModelProvider.notifier).stopRecording();
                  } else {
                    ref.read(cameraViewModelProvider.notifier).startRecording();
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
