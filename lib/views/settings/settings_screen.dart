import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/camera_state.dart';
import '../../services/settings_service.dart';
import '../../viewmodels/camera_viewmodel.dart';

/// アプリ設定画面
///
/// カメラの解像度、グリッド表示などの設定を行う画面。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraViewModelProvider);
    final viewModel = ref.read(cameraViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black87,
      body: ListView(
        children: [
          _buildSectionHeader('カメラ設定'),
          // 解像度設定
          ListTile(
            title: const Text('解像度', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              SettingsService.resolutionLabel(cameraState.resolutionPreset),
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            onTap: () => _showResolutionDialog(context, ref, cameraState),
          ),
          const Divider(color: Colors.white24, height: 1),
          // グリッド表示設定
          SwitchListTile(
            title: const Text('グリッド表示', style: TextStyle(color: Colors.white)),
            value: cameraState.showGrid,
            onChanged: (bool value) {
              viewModel.toggleGrid();
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          const Divider(color: Colors.white24, height: 1),
          // 録画終了後の滑走者確認表示設定
          SwitchListTile(
            title: const Text(
              '録画終了後に滑走者を確認する',
              style: TextStyle(color: Colors.white),
            ),
            value: cameraState.showPersonSelectionConfirmation,
            onChanged: (bool value) {
              viewModel.toggleShowPersonSelectionConfirmation();
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          const Divider(color: Colors.white24, height: 1),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showResolutionDialog(
    BuildContext context,
    WidgetRef ref,
    CameraState cameraState,
  ) {
    final viewModel = ref.read(cameraViewModelProvider.notifier);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('解像度設定', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ResolutionPreset.values.map((preset) {
              final isSelected = preset == cameraState.resolutionPreset;
              return ListTile(
                title: Text(
                  SettingsService.resolutionLabel(preset),
                  style: const TextStyle(color: Colors.white),
                ),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(dialogContext).primaryColor
                      : Colors.white54,
                ),
                onTap: () {
                  viewModel.setResolutionPreset(preset);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
