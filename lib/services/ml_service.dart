import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

class MLService {
  final ObjectDetector _objectDetector;

  MLService()
    : _objectDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.stream,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );

  Future<List<DetectedObject>> detectObjects(InputImage inputImage) async {
    return await _objectDetector.processImage(inputImage);
  }

  Future<List<double>> extractColorFeatures(
    CameraImage image,
    ui.Rect boundingBox,
  ) async {
    // TODO: Implement HSV color extraction from CameraImage within boundingBox
    // This is a placeholder
    return [0.0, 0.0, 0.0];
  }

  void dispose() {
    _objectDetector.close();
  }
}
