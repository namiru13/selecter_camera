/// FFmpeg動画処理サービス
///
/// FFmpegを使用したサムネイル画像生成や動画結合処理を提供する。
/// 人物の名前と画像を含むサムネイル動画を生成し、
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
  /// 人物の名前と画像を含むサムネイル画像をPNG形式で生成する。
  /// [personName] 人物名（null の場合は名前を表示しない）
  /// [personImagePath] 人物の参照画像パス（null の場合はデフォルト画像を使用）
  /// [width] 出力画像の幅（デフォルト: 1280）
  /// [height] 出力画像の高さ（デフォルト: 720）
  Future<String?> generateThumbnailImage({
    String? personName,
    String? personImagePath,
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

      // 背景（黒）またはダークグレー
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = const Color(0xFF1A1A1A),
      );

      // personImagePath があれば画像を描画
      double textStartY = (height / 2) - 40;
      if (personImagePath != null) {
        try {
          final file = File(personImagePath);
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frameInfo = await codec.getNextFrame();
          final personImage = frameInfo.image;

          // 画像を縮小・中央上部に配置
          final imgWidth = 400.0;
          final imgHeight = 400.0 * (personImage.height / personImage.width);
          final imgX = (width - imgWidth) / 2;
          final imgY = (height / 2) - imgHeight + 60; // 高さ調整

          final srcRect = Rect.fromLTWH(
            0,
            0,
            personImage.width.toDouble(),
            personImage.height.toDouble(),
          );
          final dstRect = Rect.fromLTWH(imgX, imgY, imgWidth, imgHeight);

          // 角丸クリップ
          canvas.save();
          final rRect = RRect.fromRectAndRadius(
            dstRect,
            const Radius.circular(20),
          );
          canvas.clipRRect(rRect);
          canvas.drawImageRect(personImage, srcRect, dstRect, Paint());
          canvas.restore();

          textStartY = imgY + imgHeight + 40; // 画像の下にテキストを配置
        } catch (e) {
          debugPrint('画像ロードエラー: $e');
        }
      }

      // 中央にテキスト情報を描画
      final textPainter = TextPainter(
        text: TextSpan(
          text: personName ?? '不明な人物',
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
        Offset((width - textPainter.width) / 2, textStartY),
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

  /// サムネイル画像から動画を作成し、メイン動画と結合して、メタデータ（カバー画像）を設定する一連の処理
  ///
  /// [sourceVideoPath] 元の動画パス
  /// [thumbnailImagePath] 生成済みのサムネイル画像パス
  /// [thumbnailDuration] サムネイル動画の表示時間（秒）
  /// [outputPath] 出力先の動画パス
  Future<bool> processVideoWithThumbnail({
    required String sourceVideoPath,
    required String thumbnailImagePath,
    double thumbnailDuration = 2.0,
    required String outputPath,
  }) async {
    try {
      // 冒頭数秒間の映像（0秒〜thumbnailDuration秒）の上に、サムネイル画像を上書き描画する。
      // - filter_complex で、入力画像[1:v]を元動画[0:v]のサイズにスケーリングし、元映像にoverlayする。
      // - enable='between(t,0,thumbnailDuration)' で表示区間を制御。
      // - 音声はそのまま (-c:a copy) 用いる。
      // - 映像は再エンコードされるためスマートフォン向けに高速エンコードオプション（ultrafast）を適用。

      final command =
          '-i "$sourceVideoPath" -i "$thumbnailImagePath" -filter_complex "[1:v][0:v]scale2ref=w=iw:h=ih[scaled_thumb][vid];[vid][scaled_thumb]overlay=x=0:y=0:enable=\'between(t,0,$thumbnailDuration)\'[out]" -map "[out]" -map 0:a? -c:v libx264 -preset ultrafast -crf 28 -c:a copy "$outputPath"';

      debugPrint('FFmpeg サムネイル焼き付け(オーバーレイ)コマンド実行: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('サムネイル焼き付け動画の生成成功: $outputPath');
        return true;
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('サムネイル焼き付け動画の生成失敗: $logs');
        return false;
      }
    } catch (e) {
      debugPrint('processVideoWithThumbnail エラー: $e');
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
