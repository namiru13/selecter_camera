/// 動画保存サービス
///
/// 録画された動画のファイル処理、アプリ専用フォルダへの保存、
/// ギャラリーへの保存、および動画の削除を担当する。
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

/// アプリ専用動画フォルダ名
const String _appVideoFolderName = 'SelecterCamera';

/// 動画保存の結果を表すクラス
class VideoSaveResult {
  /// 保存が成功したかどうか
  final bool success;

  /// 元の動画ファイルのパス
  final String? videoPath;

  /// アプリ専用フォルダでの保存先パス
  final String? savedPath;

  /// エラーメッセージ（失敗時のみ）
  final String? errorMessage;

  const VideoSaveResult({
    required this.success,
    this.videoPath,
    this.savedPath,
    this.errorMessage,
  });

  /// 成功結果を生成
  factory VideoSaveResult.ok(String videoPath, String savedPath) =>
      VideoSaveResult(
        success: true,
        videoPath: videoPath,
        savedPath: savedPath,
      );

  /// エラー結果を生成
  factory VideoSaveResult.error(String message) =>
      VideoSaveResult(success: false, errorMessage: message);
}

/// 動画ファイルの保存処理を管理するサービス
class VideoSaveService {
  /// アプリ専用の動画保存ディレクトリを取得（存在しない場合は作成）
  Future<Directory> getAppVideoDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDocDir.path}/$_appVideoFolderName');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
      debugPrint('アプリ専用動画フォルダを作成: ${videoDir.path}');
    }
    return videoDir;
  }

  /// ソースファイルをアプリ専用フォルダにコピー保存する
  ///
  /// タイムスタンプ付きのファイル名で保存し、保存先パスを返す。
  Future<String> _saveToAppFolder(String sourcePath) async {
    final videoDir = await getAppVideoDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = '${videoDir.path}/$timestamp.mp4';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    debugPrint('アプリ専用フォルダに保存完了: $destPath');

    return destPath;
  }

  /// 録画ファイルをアプリ専用フォルダとギャラリーに保存する
  ///
  /// [sourcePath] 録画された動画ファイルのパス
  ///
  /// 処理フロー:
  /// 1. ソースファイルの存在確認
  /// 2. アプリ専用フォルダへのコピー保存
  /// 3. ギャラリーへの保存
  Future<VideoSaveResult> saveToGallery(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return VideoSaveResult.error('録画ファイルが見つかりません: $sourcePath');
      }
      debugPrint('ファイルサイズ: ${await sourceFile.length()} bytes');

      // アプリ専用フォルダに保存
      final savedPath = await _saveToAppFolder(sourcePath);

      // ギャラリーに保存（アプリ専用フォルダに保存したファイルを使用）
      debugPrint('ギャラリーへの保存を開始...');
      await Gal.putVideo(savedPath);
      debugPrint('ギャラリーへの保存成功');

      return VideoSaveResult.ok(sourcePath, savedPath);
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

  /// 動画ファイルを削除する
  ///
  /// アプリ専用フォルダ内のファイルを削除する。
  /// [filePath] 削除する動画ファイルのパス
  Future<bool> deleteVideo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('動画を削除: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('動画削除エラー: $e');
      return false;
    }
  }

  /// アプリ専用フォルダ内の全動画ファイルを取得する
  ///
  /// 更新日時の降順（新しい順）でソートして返す。
  Future<List<File>> getVideoList() async {
    final videoDir = await getAppVideoDirectory();

    if (!await videoDir.exists()) {
      return [];
    }

    final files = <File>[];
    await for (final entity in videoDir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.mp4')) {
        files.add(entity);
      }
    }

    // 更新日時の降順でソート（新しいファイルが先頭）
    files.sort((a, b) {
      final aTime = a.lastModifiedSync();
      final bTime = b.lastModifiedSync();
      return bTime.compareTo(aTime);
    });

    return files;
  }
}
