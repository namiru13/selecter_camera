/// 人物一覧画面
///
/// 登録された人物のサムネイルと名前をグリッド形式で表示する。
/// グリッドのカラム数をスライダーで調整可能。
/// 右下のFABで人物登録画面に遷移する。
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/person_model.dart';
import '../../viewmodels/person_viewmodel.dart';
import 'person_edit_screen.dart';

/// グリッドのカラム数を管理するNotifier
class _GridColumnNotifier extends Notifier<int> {
  @override
  int build() => 3;

  void set(int count) => state = count;
}

/// グリッドのカラム数を管理するプロバイダー
final gridColumnCountProvider = NotifierProvider<_GridColumnNotifier, int>(
  _GridColumnNotifier.new,
);

/// 人物一覧画面ウィジェット
class PersonListScreen extends ConsumerWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(personViewModelProvider);
    final columnCount = ref.watch(gridColumnCountProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('人物一覧'),
        actions: [
          // グリッドサイズ調整アイコン
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () => _showGridSizeDialog(context, ref, columnCount),
          ),
        ],
      ),
      body: personsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'エラー: $error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(personViewModelProvider.notifier).reload(),
                child: const Text('再読込'),
              ),
            ],
          ),
        ),
        data: (persons) {
          if (persons.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, color: Colors.white38, size: 80),
                  SizedBox(height: 16),
                  Text(
                    '人物が登録されていません\n右下の＋ボタンから追加してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: persons.length,
            itemBuilder: (context, index) {
              return _PersonGridItem(
                person: persons[index],
                onTap: () => _navigateToEdit(context, persons[index]),
                onLongPress: () =>
                    _showDeleteDialog(context, ref, persons[index]),
              );
            },
          );
        },
      ),
      // 右下の「+」ボタン
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () => _navigateToAdd(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  /// 人物登録画面へ遷移する
  void _navigateToAdd(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PersonEditScreen()));
  }

  /// 人物編集画面へ遷移する
  void _navigateToEdit(BuildContext context, PersonModel person) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PersonEditScreen(person: person)));
  }

  /// グリッドサイズ変更ダイアログを表示する
  void _showGridSizeDialog(
    BuildContext context,
    WidgetRef ref,
    int currentCount,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('表示サイズ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [2, 3, 4].map((count) {
              final isSelected = count == currentCount;
              return ListTile(
                title: Text('$count列'),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(dialogContext).primaryColor
                      : null,
                ),
                onTap: () {
                  ref.read(gridColumnCountProvider.notifier).set(count);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 削除確認ダイアログを表示する
  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    PersonModel person,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('「${person.name}」を削除しますか？\n関連する写真もすべて削除されます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(personViewModelProvider.notifier)
                    .deletePerson(person.id);
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }
}

/// 人物グリッドアイテムウィジェット
class _PersonGridItem extends StatelessWidget {
  final PersonModel person;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PersonGridItem({
    required this.person,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // サムネイル写真
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildThumbnail(),
              ),
            ),
            // 名前
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                person.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// サムネイル画像を構築する
  Widget _buildThumbnail() {
    final thumbPath = person.thumbnailPath;
    if (thumbPath != null && File(thumbPath).existsSync()) {
      return Image.file(File(thumbPath), fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.person, color: Colors.white38, size: 48),
      ),
    );
  }
}
