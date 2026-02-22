import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/camera_viewmodel.dart';
import '../../../viewmodels/person_viewmodel.dart';

/// 画面左端に配置される人物一覧リスト
class PersonListSideBar extends ConsumerWidget {
  const PersonListSideBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(personViewModelProvider);
    final selectedPersonId = ref
        .watch(cameraViewModelProvider)
        .selectedPersonId;

    return personsAsync.when(
      data: (persons) {
        if (persons.isEmpty) return const SizedBox.shrink();

        // 画面の向きに合わせて並び方向を決定
        // 要望により、横画面（landscape）でも画面左端の上から下に並べるため、常に縦方向にする
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 220, // 最大幅は制限するが、固定幅ではなくテキストに合わせる
            maxHeight: MediaQuery.of(context).size.height * 0.8, // 画面高さを超えないように
          ),
          child: ListView.separated(
            shrinkWrap: true, // コンテンツの高さに合わせてリストを縮小する
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            itemCount: persons.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 0, height: 12),
            itemBuilder: (context, index) {
              final person = persons[index];
              final isSelected = selectedPersonId == person.id;

              Widget textWidget = Text(
                person.name,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
              );

              return Align(
                alignment: Alignment.centerLeft, // 左寄せで、自身のサイズだけになるようにする
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54, // 黒色ベースの透過
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      ref
                          .read(cameraViewModelProvider.notifier)
                          .setSelectedPersonId(isSelected ? null : person.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // コンテンツに合わせて最小幅にする
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 64, // 36 * 16 / 9 = 64
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    )
                                  : Border.all(color: Colors.white24, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: person.thumbnailPath != null
                                  ? Image.file(
                                      File(person.thumbnailPath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 名前のテキスト部分は、RowのmainAxisSizeがminなので通常表示する
                          // ただし長すぎるとオーバーフローするため、Flexibleを使用する
                          Flexible(child: textWidget),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// 画面右上に配置される、選択された人物のポップアップ
class SelectedPersonsTopRight extends ConsumerWidget {
  final double rotationTurns;

  const SelectedPersonsTopRight({super.key, this.rotationTurns = 0.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraViewModelProvider);
    final personsAsync = ref.watch(personViewModelProvider);
    final selectedPersonId = cameraState.selectedPersonId;

    if (selectedPersonId == null) {
      return const SizedBox.shrink();
    }

    return personsAsync.when(
      data: (persons) {
        // 選択された人物を取得
        final selectedPerson = persons
            .where((p) => p.id == selectedPersonId)
            .toList();

        if (selectedPerson.isEmpty) return const SizedBox.shrink();

        final person = selectedPerson.first;

        return GestureDetector(
          onTap: () {
            // タップで選択解除
            ref
                .read(cameraViewModelProvider.notifier)
                .setSelectedPersonId(null);
          },
          child: AnimatedRotation(
            turns: rotationTurns,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 42.6, // 24 * 16 / 9 = 42.6
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: person.thumbnailPath != null
                          ? Image.file(
                              File(person.thumbnailPath!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    person.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
