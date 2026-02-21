/// FFmpeg動画処理サービス
///
/// FFmpegを使用したサムネイル画像生成や動画結合処理を提供する。
/// 滑走者の名前と画像を含むサムネイル動画を生成し、
/// メイン動画と結合する機能を持つ。
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// FFmpeg動画処理サービス
class FFmpegService {
  /// サムネイル画像を生成する（Canvas描画）
  ///
  /// 滑走者の名前と画像を含むサムネイル画像をPNG形式で生成する。
  /// [skierName] 滑走者名（null の場合は名前を表示しない）
  /// [skierImagePath] 滑走者の参照画像パス（null の場合はデフォルト画像を使用）
  /// [width] 出力画像の幅（デフォルト: 1280）
  /// [height] 出力画像の高さ（デフォルト: 720）
  Future<String?> generateThumbnailImage({
    String? skierName,
    String? skierImagePath,
    int width = 1280,
    int height = 720,
  }) async {
    try {
      // Canvas描画でサムネイル画像を生成
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      );

      // 背景（黒）
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = const Color(0xFF000000),
      );

      // 中央にテキスト情報を描画
      final textPainter = TextPainter(
        text: TextSpan(
          text: skierName ?? 'Unknown Skier',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width.toDouble() - 100);
      textPainter.paint(
        canvas,
        Offset(
          (width - textPainter.width) / 2,
          (height - textPainter.height) / 2,
        ),
      );

      // 画像をPNGエンコード
      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      // 一時ファイルに保存
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(outputPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint('サムネイル画像を生成: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('サムネイル画像生成エラー: $e');
      return null;
    }
  }

  /// サムネイル画像から短い動画を生成する
  ///
  /// [imagePath] 入力画像のパス
  /// [duration] 動画の長さ（秒）
  /// [outputPath] 出力先パス
  Future<bool> generateThumbnailVideo({
    required String imagePath,
    double duration = 2.0,
    String? outputPath,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final output =
          outputPath ??
          '${tempDir.path}/thumb_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final command =
          '-loop 1 -i "$imagePath" -c:v mpeg4 -t $duration -pix_fmt yuv420p "$output"';

      debugPrint('FFmpegコマンド実行: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('サムネイル動画の生成成功: $output');
        return true;
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('サムネイル動画生成失敗: $logs');
        return false;
      }
    } catch (e) {
      debugPrint('サムネイル動画生成エラー: $e');
      return false;
    }
  }

  /// 2つの動画を結合する
  ///
  /// [video1Path] 先頭に配置する動画（サムネイル動画）
  /// [video2Path] メイン動画
  /// [outputPath] 出力先パス
  Future<bool> concatenateVideos({
    required String video1Path,
    required String video2Path,
    String? outputPath,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final output =
          outputPath ??
          '${tempDir.path}/concat_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // 結合用の一時ファイルリストを作成
      final listPath =
          '${tempDir.path}/concat_list_${DateTime.now().millisecondsSinceEpoch}.txt';
      final listFile = File(listPath);
      await listFile.writeAsString("file '$video1Path'\nfile '$video2Path'\n");

      final command = '-f concat -safe 0 -i "$listPath" -c copy "$output"';

      debugPrint('FFmpegコマンド実行: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // 一時ファイルリストを削除
      try {
        await listFile.delete();
      } catch (_) {}

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('動画結合成功: $output');
        return true;
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('動画結合失敗: $logs');
        return false;
      }
    } catch (e) {
      debugPrint('動画結合エラー: $e');
      return false;
    }
  }

  /// 一時ファイルをクリーンアップする
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final entities = tempDir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.startsWith('thumbnail_') ||
              name.startsWith('thumb_video_') ||
              name.startsWith('concat_list_') ||
              name.startsWith('concat_')) {
            await entity.delete();
          }
        }
      }
      debugPrint('一時ファイルをクリーンアップしました');
    } catch (e) {
      debugPrint('クリーンアップエラー: $e');
    }
  }
}
