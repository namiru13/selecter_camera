/// 人物登録・編集画面
///
/// 人物の名前と写真（最大5枚）を登録・編集できる。
/// 写真のいずれか一つをサムネイル用に設定可能。
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../models/person_model.dart';
import '../../viewmodels/person_viewmodel.dart';

/// 人物登録・編集画面ウィジェット
class PersonEditScreen extends ConsumerStatefulWidget {
  /// 編集対象の人物（nullの場合は新規登録）
  final PersonModel? person;

  const PersonEditScreen({super.key, this.person});

  @override
  ConsumerState<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends ConsumerState<PersonEditScreen> {
  late TextEditingController _nameController;
  final ImagePicker _imagePicker = ImagePicker();

  /// 現在編集中の人物データ（新規登録後はnullから更新される）
  PersonModel? _currentPerson;

  /// 新規登録モードかどうか
  bool get _isNewMode => widget.person == null && _currentPerson == null;

  /// 現在の人物データ（編集中のものを優先）
  PersonModel? get _person => _currentPerson ?? widget.person;

  /// 保存処理中フラグ
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _currentPerson = widget.person;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // プロバイダーの変更を監視して最新の人物データを取得
    final personsAsync = ref.watch(personViewModelProvider);
    final person = personsAsync.whenOrNull(
      data: (persons) {
        if (_person != null) {
          final found = persons.where((p) => p.id == _person!.id);
          if (found.isNotEmpty) return found.first;
        }
        return null;
      },
    );

    // プロバイダーの最新データがあれば更新
    if (person != null && person != _currentPerson) {
      _currentPerson = person;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_isNewMode ? '人物登録' : '人物編集'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 名前入力フィールド
            _buildNameField(),
            const SizedBox(height: 24),

            // 新規登録モードの場合：まず名前を保存するボタン
            if (_isNewMode) _buildCreateButton(),

            // 写真セクション（登録済みの場合のみ表示）
            if (!_isNewMode) ...[_buildPhotoSection()],
          ],
        ),
      ),
    );
  }

  /// 名前入力フィールドを構築する
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '名前',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: '人物の名前を入力',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            // 編集モードの場合、名前変更を自動保存
            if (_person != null && value.isNotEmpty) {
              _updateName(value);
            }
          },
        ),
      ],
    );
  }

  /// 新規登録ボタンを構築する
  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _createPerson,
        icon: const Icon(Icons.person_add),
        label: Text(_isSaving ? '登録中...' : '登録して写真を追加'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// 写真セクションを構築する
  Widget _buildPhotoSection() {
    final person = _person;
    if (person == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '写真 (${person.photoPaths.length}/${PersonModel.maxPhotos})',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (person.canAddPhoto)
              TextButton.icon(
                onPressed: _showPhotoSourceDialog,
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('追加'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (person.photoPaths.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white38,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text('写真を追加してください', style: TextStyle(color: Colors.white38)),
                ],
              ),
            ),
          )
        else
          _buildPhotoGrid(person),
      ],
    );
  }

  /// 写真グリッドを構築する
  Widget _buildPhotoGrid(PersonModel person) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: person.photoPaths.length,
      itemBuilder: (context, index) {
        final isThumbnail = index == person.thumbnailIndex;
        return _buildPhotoItem(person, index, isThumbnail);
      },
    );
  }

  /// 写真アイテムを構築する
  Widget _buildPhotoItem(PersonModel person, int index, bool isThumbnail) {
    return GestureDetector(
      onTap: () => _showPhotoActions(person, index, isThumbnail),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 写真画像
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(person.photoPaths[index]),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white38,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
          // サムネイルマーカー
          if (isThumbnail)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'サムネイル',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // サムネイル枠線
          if (isThumbnail)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 写真のアクションダイアログを表示する
  void _showPhotoActions(PersonModel person, int index, bool isThumbnail) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (!isThumbnail)
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.blue),
                  title: const Text(
                    'サムネイルに設定',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _setThumbnail(person.id, index);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.fullscreen, color: Colors.white70),
                title: const Text(
                  '拡大表示',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _showFullScreenPhoto(person.photoPaths[index]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _confirmDeletePhoto(person.id, index);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 写真のソース選択ダイアログを表示する
  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white70),
                title: const Text(
                  'カメラで撮影',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: const Text(
                  'ギャラリーから選択',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 写真を拡大表示する
  void _showFullScreenPhoto(String photoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(child: Image.file(File(photoPath))),
          ),
        ),
      ),
    );
  }

  /// 人物を新規作成する
  Future<void> _createPerson() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackBar('名前を入力してください');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final person = await ref
          .read(personViewModelProvider.notifier)
          .addPerson(name);
      if (mounted) {
        setState(() {
          _currentPerson = person;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('登録に失敗しました: $e');
      }
    }
  }

  /// 名前を更新する（デバウンスなし、変更時に即時保存）
  Future<void> _updateName(String name) async {
    final person = _person;
    if (person == null || name.isEmpty) return;

    try {
      await ref
          .read(personViewModelProvider.notifier)
          .updatePersonName(person.id, name);
    } catch (e) {
      // 名前更新エラーは静的に処理
      debugPrint('名前更新エラー: $e');
    }
  }

  /// 写真を選択して追加する
  Future<void> _pickPhoto(ImageSource source) async {
    final person = _person;
    if (person == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        // 画像を切り取る
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '写真の切り取り',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: '写真の切り取り',
              cancelButtonTitle: 'キャンセル',
              doneButtonTitle: '完了',
              aspectRatioLockEnabled: false,
            ),
          ],
        );

        // 切り取りがキャンセルされた場合は処理を中断
        if (croppedFile == null) return;

        if (mounted) {
          final updatedPerson = await ref
              .read(personViewModelProvider.notifier)
              .addPhoto(person.id, croppedFile.path);
          setState(() => _currentPerson = updatedPerson);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('写真の追加に失敗しました: $e');
      }
    }
  }

  /// サムネイルインデックスを設定する
  Future<void> _setThumbnail(String personId, int index) async {
    try {
      final updatedPerson = await ref
          .read(personViewModelProvider.notifier)
          .setThumbnailIndex(personId, index);
      setState(() => _currentPerson = updatedPerson);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('サムネイル設定に失敗しました: $e');
      }
    }
  }

  /// 写真削除の確認ダイアログを表示する
  void _confirmDeletePhoto(String personId, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('写真の削除'),
          content: const Text('この写真を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deletePhoto(personId, index);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  /// 写真を削除する
  Future<void> _deletePhoto(String personId, int index) async {
    try {
      final updatedPerson = await ref
          .read(personViewModelProvider.notifier)
          .removePhoto(personId, index);
      setState(() => _currentPerson = updatedPerson);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('写真の削除に失敗しました: $e');
      }
    }
  }

  /// エラーSnackBarを表示する
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }
}
