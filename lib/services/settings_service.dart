/// 設定管理サービス
///
/// SharedPreferencesを使用してアプリ設定（解像度、グリッド表示等）を永続化する。
library;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SettingsServiceのRiverpod Provider
final settingsServiceProvider = Provider((ref) => SettingsService());

/// 設定管理サービス
class SettingsService {
  static const String _keyResolution = 'resolution_preset';
  static const String _keyShowGrid = 'show_grid';

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
}
