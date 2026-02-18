import 'package:flutter_test/flutter_test.dart';
import 'package:selecter_camera/services/video_save_service.dart';

void main() {
  group('VideoSaveResult', () {
    test('成功結果の生成', () {
      final result = VideoSaveResult.ok(
        '/path/to/video.mp4',
        '/saved/path/video.mp4',
      );

      expect(result.success, true);
      expect(result.videoPath, '/path/to/video.mp4');
      expect(result.savedPath, '/saved/path/video.mp4');
      expect(result.errorMessage, isNull);
    });

    test('エラー結果の生成', () {
      final result = VideoSaveResult.error('ファイルが見つかりません');

      expect(result.success, false);
      expect(result.videoPath, isNull);
      expect(result.errorMessage, 'ファイルが見つかりません');
    });
  });

  group('VideoSaveService', () {
    late VideoSaveService service;

    setUp(() {
      service = VideoSaveService();
    });

    test('存在しないファイルの保存はエラーを返す', () async {
      final result = await service.saveToGallery('/nonexistent/path/video.mp4');

      expect(result.success, false);
      expect(result.errorMessage, contains('録画ファイルが見つかりません'));
    });
  });
}
