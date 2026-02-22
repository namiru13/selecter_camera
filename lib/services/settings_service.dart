/// 設定管理サービス
///
/// SharedPreferencesを使用してアプリ設定（解像度、グリッド表示等）を永続化する。
library;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera_state.dart';

/// SettingsServiceのRiverpod Provider
final settingsServiceProvider = Provider((ref) => SettingsService());

/// 設定管理サービス
class SettingsService {
  static const String _keyResolution = 'resolution_preset';
  static const String _keyShowGrid = 'show_grid';
  // 古い設定キー（マイグレーション用）
  static const String _keyShowPersonSelectionOnStop =
      'show_person_selection_on_stop';
  // 新しい設定キー
  static const String _keyConfirmPersonSelectionMode =
      'confirm_person_selection_mode';

  /// 保存された解像度設定を取得する
  Future<ResolutionPreset> getResolutionPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyResolution) ?? ResolutionPreset.high.index;
    if (index >= 0 && index < ResolutionPreset.values.length) {
      return ResolutionPreset.values[index];
    }
    return ResolutionPreset.high;
  }

  /// 解像度設定を保存する
  Future<void> setResolutionPreset(ResolutionPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyResolution, preset.index);
  }

  /// グリッド表示設定を取得する
  Future<bool> getShowGrid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowGrid) ?? false;
  }

  /// グリッド表示設定を保存する
  Future<void> setShowGrid(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowGrid, show);
  }

  /// 撮影終了後の滑走者確認表示モードを取得する
  Future<ConfirmPersonSelectionMode> getConfirmPersonSelectionMode() async {
    final prefs = await SharedPreferences.getInstance();

    // 新しい設定が存在するか確認
    if (prefs.containsKey(_keyConfirmPersonSelectionMode)) {
      final index =
          prefs.getInt(_keyConfirmPersonSelectionMode) ??
          ConfirmPersonSelectionMode.always.index;
      if (index >= 0 && index < ConfirmPersonSelectionMode.values.length) {
        return ConfirmPersonSelectionMode.values[index];
      }
      return ConfirmPersonSelectionMode.always;
    }

    // 古い設定からのマイグレーションを試みる
    if (prefs.containsKey(_keyShowPersonSelectionOnStop)) {
      final showPersonSelectionOnStop =
          prefs.getBool(_keyShowPersonSelectionOnStop) ?? true;
      final mode = showPersonSelectionOnStop
          ? ConfirmPersonSelectionMode.always
          : ConfirmPersonSelectionMode.never;
      // 新しい設定に保存
      await setConfirmPersonSelectionMode(mode);
      return mode;
    }

    // デフォルト値
    return ConfirmPersonSelectionMode.always;
  }

  /// 撮影終了後の滑走者確認表示モードを保存する
  Future<void> setConfirmPersonSelectionMode(
    ConfirmPersonSelectionMode mode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConfirmPersonSelectionMode, mode.index);
    // 古い設定キーは必要ないので削除（任意だが整理のため）
    await prefs.remove(_keyShowPersonSelectionOnStop);
  }

  /// 解像度プリセットの表示名を返す
  static String resolutionLabel(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return '低画質 (240p)';
      case ResolutionPreset.medium:
        return '中画質 (480p)';
      case ResolutionPreset.high:
        return '高画質 (720p)';
      case ResolutionPreset.veryHigh:
        return '超高画質 (1080p)';
      case ResolutionPreset.ultraHigh:
        return '最高画質 (2160p)';
      case ResolutionPreset.max:
        return '最大';
    }
  }

  /// 人物確認モードの表示名を返す
  static String confirmModeLabel(ConfirmPersonSelectionMode mode) {
    switch (mode) {
      case ConfirmPersonSelectionMode.always:
        return '常に確認する';
      case ConfirmPersonSelectionMode.onlyWhenUnselected:
        return '未選択時のみ確認する';
      case ConfirmPersonSelectionMode.never:
        return '確認しない';
    }
  }
}
