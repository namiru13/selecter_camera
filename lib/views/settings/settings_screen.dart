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
          // 水準器表示設定
          SwitchListTile(
            title: const Text('水準器表示', style: TextStyle(color: Colors.white)),
            value: cameraState.showLeveler,
            onChanged: (bool value) {
              viewModel.toggleLeveler();
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          const Divider(color: Colors.white24, height: 1),
          // 録画終了後の滑走者確認表示設定
          ListTile(
            title: const Text(
              '録画終了後に滑走者を確認する',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              SettingsService.confirmModeLabel(
                cameraState.confirmPersonSelectionMode,
              ),
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            onTap: () => _showConfirmModeDialog(context, ref, cameraState),
          ),
          const Divider(color: Colors.white24, height: 1),
          _buildSectionHeader('露出調整'),
          // 露出モード設定
          ListTile(
            title: const Text('露出モード', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              SettingsService.exposureAdjustmentModeLabel(
                cameraState.exposureAdjustmentMode,
              ),
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            onTap: () => _showExposureModeDialog(context, ref, cameraState),
          ),
          if (cameraState.exposureAdjustmentMode ==
              ExposureAdjustmentMode.manual) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '露出オフセット (EV)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            Slider(
              value: cameraState.exposureOffset,
              min: cameraState.minExposureOffset,
              max: cameraState.maxExposureOffset,
              divisions: cameraState.exposureOffsetStepSize > 0
                  ? ((cameraState.maxExposureOffset -
                                cameraState.minExposureOffset) /
                            cameraState.exposureOffsetStepSize)
                        .round()
                  : null,
              label: cameraState.exposureOffset.toStringAsFixed(1),
              onChanged: (double value) {
                viewModel.setExposureOffset(value);
              },
              activeColor: Theme.of(context).primaryColor,
              inactiveColor: Colors.white24,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cameraState.minExposureOffset.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    cameraState.exposureOffset.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cameraState.maxExposureOffset.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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

  void _showExposureModeDialog(
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
          title: const Text('露出調整モード', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ExposureAdjustmentMode.values.map((mode) {
              final isSelected = mode == cameraState.exposureAdjustmentMode;
              return ListTile(
                title: Text(
                  SettingsService.exposureAdjustmentModeLabel(mode),
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
                  viewModel.setExposureAdjustmentMode(mode);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showConfirmModeDialog(
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
          title: const Text('滑走者の確認設定', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ConfirmPersonSelectionMode.values.map((mode) {
              final isSelected = mode == cameraState.confirmPersonSelectionMode;
              return ListTile(
                title: Text(
                  SettingsService.confirmModeLabel(mode),
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
                  viewModel.setConfirmPersonSelectionMode(mode);
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
