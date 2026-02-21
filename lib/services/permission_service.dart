/// パーミッション管理サービス
///
/// カメラ・マイク・ストレージの権限リクエストを一括管理する。
/// 権限が拒否された場合はアプリ設定ページへの誘導を行う。
library;

import 'package:permission_handler/permission_handler.dart';

/// パーミッション管理サービス
class PermissionService {
  /// 必要な全権限をリクエストする
  ///
  /// 戻り値: すべての権限が付与されたかどうか
  Future<bool> requestAllPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.videos,
    ].request();

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  /// カメラ権限が付与されているか確認する
  Future<bool> isCameraGranted() async {
    return await Permission.camera.isGranted;
  }

  /// マイク権限が付与されているか確認する
  Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  /// いずれかの権限が永久に拒否されているか確認する
  Future<bool> isAnyPermanentlyDenied() async {
    final camera = await Permission.camera.isPermanentlyDenied;
    final microphone = await Permission.microphone.isPermanentlyDenied;
    return camera || microphone;
  }

  /// アプリの設定ページを開く（権限が永久に拒否された場合に使用）
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
