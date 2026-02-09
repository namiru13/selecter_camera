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
            SizedBox.expand(child: CameraPreview(cameraState.controller!))
          else
            const Center(child: CircularProgressIndicator()),

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
