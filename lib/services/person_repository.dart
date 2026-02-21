import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/person_model.dart';

/// 人物データのリポジトリ
///
/// SharedPreferencesにメタデータを、アプリのドキュメントディレクトリに写真ファイルを保存する。
class PersonRepository {
  static const String _prefsKey = 'persons_data';
  static const String _photoDirName = 'person_photos';

  /// 全人物データを読み込む
  Future<List<PersonModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    return await compute(PersonModel.decodeList, jsonString);
  }

  /// 人物データリストを保存する
  Future<void> _saveAll(List<PersonModel> persons) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = await compute(PersonModel.encodeList, persons);
    await prefs.setString(_prefsKey, jsonString);
  }

  /// 新しい人物を追加する
  Future<PersonModel> addPerson(String name) async {
    final persons = await loadAll();
    final newPerson = PersonModel(id: const Uuid().v4(), name: name);
    persons.add(newPerson);
    await _saveAll(persons);
    return newPerson;
  }

  /// 人物データを更新する
  Future<void> updatePerson(PersonModel person) async {
    final persons = await loadAll();
    final index = persons.indexWhere((p) => p.id == person.id);
    if (index != -1) {
      persons[index] = person;
      await _saveAll(persons);
    }
  }

  /// 人物データを削除する（関連写真も削除）
  Future<void> deletePerson(String personId) async {
    final persons = await loadAll();
    final person = persons.firstWhere(
      (p) => p.id == personId,
      orElse: () => throw Exception('人物が見つかりません: $personId'),
    );

    // 関連する写真ファイルを削除
    for (final photoPath in person.photoPaths) {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    persons.removeWhere((p) => p.id == personId);
    await _saveAll(persons);
  }

  /// 写真を追加する（ソースファイルをアプリディレクトリにコピー）
  Future<PersonModel> addPhoto(String personId, String sourceFilePath) async {
    final persons = await loadAll();
    final index = persons.indexWhere((p) => p.id == personId);
    if (index == -1) {
      throw Exception('人物が見つかりません: $personId');
    }

    final person = persons[index];
    if (!person.canAddPhoto) {
      throw Exception('写真は最大${PersonModel.maxPhotos}枚までです');
    }

    // 写真をアプリディレクトリにコピー
    final destPath = await _copyPhotoToAppDir(personId, sourceFilePath);

    final updatedPhotos = [...person.photoPaths, destPath];
    final updatedPerson = person.copyWith(photoPaths: updatedPhotos);
    persons[index] = updatedPerson;
    await _saveAll(persons);
    return updatedPerson;
  }

  /// 写真を削除する
  Future<PersonModel> removePhoto(String personId, int photoIndex) async {
    final persons = await loadAll();
    final index = persons.indexWhere((p) => p.id == personId);
    if (index == -1) {
      throw Exception('人物が見つかりません: $personId');
    }

    final person = persons[index];
    if (photoIndex < 0 || photoIndex >= person.photoPaths.length) {
      throw Exception('無効な写真インデックス: $photoIndex');
    }

    // 写真ファイルを削除
    final file = File(person.photoPaths[photoIndex]);
    if (await file.exists()) {
      await file.delete();
    }

    final updatedPhotos = [...person.photoPaths]..removeAt(photoIndex);

    // サムネイルインデックスを調整
    int newThumbnailIndex = person.thumbnailIndex;
    if (updatedPhotos.isEmpty) {
      newThumbnailIndex = 0;
    } else if (photoIndex == person.thumbnailIndex) {
      newThumbnailIndex = 0;
    } else if (photoIndex < person.thumbnailIndex) {
      newThumbnailIndex = person.thumbnailIndex - 1;
    }

    final updatedPerson = person.copyWith(
      photoPaths: updatedPhotos,
      thumbnailIndex: newThumbnailIndex,
    );
    persons[index] = updatedPerson;
    await _saveAll(persons);
    return updatedPerson;
  }

  /// サムネイルインデックスを設定する
  Future<PersonModel> setThumbnailIndex(
    String personId,
    int thumbnailIndex,
  ) async {
    final persons = await loadAll();
    final index = persons.indexWhere((p) => p.id == personId);
    if (index == -1) {
      throw Exception('人物が見つかりません: $personId');
    }

    final person = persons[index];
    if (thumbnailIndex < 0 || thumbnailIndex >= person.photoPaths.length) {
      throw Exception('無効なサムネイルインデックス: $thumbnailIndex');
    }

    final updatedPerson = person.copyWith(thumbnailIndex: thumbnailIndex);
    persons[index] = updatedPerson;
    await _saveAll(persons);
    return updatedPerson;
  }

  /// 写真をアプリのディレクトリにコピーする
  Future<String> _copyPhotoToAppDir(
    String personId,
    String sourceFilePath,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/$_photoDirName/$personId');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    final fileName = '${const Uuid().v4()}.jpg';
    final destPath = '${photoDir.path}/$fileName';

    final sourceFile = File(sourceFilePath);
    await sourceFile.copy(destPath);

    return destPath;
  }

  /// 人物用の写真ディレクトリを取得する
  Future<Directory> getPhotoDirectory(String personId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/$_photoDirName/$personId');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }
}
