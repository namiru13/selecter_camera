/// 動画保存サービス
///
/// 録画された動画のファイル処理とギャラリーへの保存を担当する。
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

/// 動画保存の結果を表すクラス
class VideoSaveResult {
  /// 保存が成功したかどうか
  final bool success;

  /// 元の動画ファイルのパス
  final String? videoPath;

  /// エラーメッセージ（失敗時のみ）
  final String? errorMessage;

  const VideoSaveResult({
    required this.success,
    this.videoPath,
    this.errorMessage,
  });

  /// 成功結果を生成
  factory VideoSaveResult.ok(String path) =>
      VideoSaveResult(success: true, videoPath: path);

  /// エラー結果を生成
  factory VideoSaveResult.error(String message) =>
      VideoSaveResult(success: false, errorMessage: message);
}

/// 動画ファイルの保存処理を管理するサービス
class VideoSaveService {
  /// 録画ファイルをギャラリーに保存する
  ///
  /// [sourcePath] 録画された動画ファイルのパス
  ///
  /// 処理フロー:
  /// 1. ソースファイルの存在確認
  /// 2. 安定したパスへのコピー（一時ファイルの無効化を防ぐ）
  /// 3. ギャラリーへの保存
  /// 4. 一時コピーファイルの削除
  Future<VideoSaveResult> saveToGallery(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return VideoSaveResult.error('録画ファイルが見つかりません: $sourcePath');
      }
      debugPrint('ファイルサイズ: ${await sourceFile.length()} bytes');

      // 安定したパスにコピー（一時ファイルの無効化を防ぐ）
      final tempDir = await getTemporaryDirectory();
      final stablePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final stableFile = await sourceFile.copy(stablePath);
      debugPrint('安定パスにコピー完了: ${stableFile.path}');

      // ギャラリーに保存
      debugPrint('ギャラリーへの保存を開始...');
      await Gal.putVideo(stableFile.path);
      debugPrint('ギャラリーへの保存成功');

      // 一時コピーファイルの削除
      try {
        await stableFile.delete();
      } catch (_) {}

      return VideoSaveResult.ok(sourcePath);
    } on GalException catch (e) {
      debugPrint('GalException: ${e.type} - ${e.toString()}');
      debugPrint('PlatformException詳細: ${e.platformException.message}');
      debugPrint('ネイティブStackTrace: ${e.platformException.stacktrace}');
      return VideoSaveResult.error('ギャラリー保存エラー: ${e.type.message}');
    } catch (e) {
      debugPrint('不明なエラー: $e');
      return VideoSaveResult.error(e.toString());
    }
  }
}
