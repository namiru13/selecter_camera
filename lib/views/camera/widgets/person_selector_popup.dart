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

        return Container(
          width: 80,
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3), // 30%透過の白色
            borderRadius: BorderRadius.circular(24), // 丸みを強くして通知バー風に
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: persons.length,
            itemBuilder: (context, index) {
              final person = persons[index];
              final isSelected = selectedPersonId == person.id;

              return InkWell(
                onTap: () {
                  ref
                      .read(cameraViewModelProvider.notifier)
                      .setSelectedPersonId(isSelected ? null : person.id);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 3,
                                ),
                              )
                            : null,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: person.thumbnailPath != null
                              ? FileImage(File(person.thumbnailPath!))
                              : null,
                          child: person.thumbnailPath == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person.name,
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
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
                        textAlign: TextAlign.center,
                      ),
                    ],
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
  const SelectedPersonsTopRight({super.key});

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
                CircleAvatar(
                  radius: 14,
                  backgroundImage: person.thumbnailPath != null
                      ? FileImage(File(person.thumbnailPath!))
                      : null,
                  child: person.thumbnailPath == null
                      ? const Icon(Icons.person, color: Colors.white, size: 16)
                      : null,
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
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
