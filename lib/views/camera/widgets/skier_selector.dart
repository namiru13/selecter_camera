/// 滑走者選択カルーセルウィジェット
///
/// 撮影待機画面の下部に滑走者選択カルーセルを表示する。
/// 「Unknown（未選択）」を含む選択肢を横スクロールで表示し、
/// タップで滑走者を選択/解除する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/skiers_viewmodel.dart';
import '../../../viewmodels/camera_viewmodel.dart';

/// 滑走者選択カルーセルウィジェット
class SkierSelector extends ConsumerWidget {
  /// 現在選択されている滑走者ID
  final String? selectedSkierId;

  const SkierSelector({super.key, this.selectedSkierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skiers = ref.watch(skierViewModelProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: skiers.length + 1, // +1 for "Unknown"
        itemBuilder: (context, index) {
          if (index == 0) {
            // 「Unknown（未選択）」の選択肢
            final isSelected = selectedSkierId == null;
            return _buildChip(
              context,
              label: '未選択',
              isSelected: isSelected,
              onTap: () {
                ref
                    .read(cameraViewModelProvider.notifier)
                    .setSelectedSkierId(null);
              },
            );
          }

          final skier = skiers[index - 1];
          final isSelected = selectedSkierId == skier.id;
          return _buildChip(
            context,
            label: skier.name,
            isSelected: isSelected,
            onTap: () {
              ref
                  .read(cameraViewModelProvider.notifier)
                  .setSelectedSkierId(skier.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isSelected
              ? Colors.yellow
              : Colors.white.withAlpha(50),
          side: BorderSide(color: isSelected ? Colors.yellow : Colors.white30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}
