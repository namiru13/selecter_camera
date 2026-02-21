import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/person_model.dart';
import '../services/person_repository.dart';

/// 人物データのViewModel
///
/// PersonRepositoryを介してデータを管理し、UIに状態を提供する。
class PersonViewModel extends AsyncNotifier<List<PersonModel>> {
  late final PersonRepository _repository;

  @override
  Future<List<PersonModel>> build() async {
    _repository = PersonRepository();
    return _repository.loadAll();
  }

  /// データを再読み込みする
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.loadAll());
  }

  /// 新しい人物を追加する
  Future<PersonModel> addPerson(String name) async {
    final person = await _repository.addPerson(name);
    await reload();
    return person;
  }

  /// 人物データを更新する
  Future<void> updatePerson(PersonModel person) async {
    await _repository.updatePerson(person);
    await reload();
  }

  /// 人物名を更新する
  Future<void> updatePersonName(String personId, String name) async {
    final persons = state.value ?? [];
    final person = persons.firstWhere((p) => p.id == personId);
    await _repository.updatePerson(person.copyWith(name: name));
    await reload();
  }

  /// 人物データを削除する
  Future<void> deletePerson(String personId) async {
    await _repository.deletePerson(personId);
    await reload();
  }

  /// 写真を追加する
  Future<PersonModel> addPhoto(String personId, String sourceFilePath) async {
    final person = await _repository.addPhoto(personId, sourceFilePath);
    await reload();
    return person;
  }

  /// 写真を削除する
  Future<PersonModel> removePhoto(String personId, int photoIndex) async {
    final person = await _repository.removePhoto(personId, photoIndex);
    await reload();
    return person;
  }

  /// サムネイルインデックスを設定する
  Future<PersonModel> setThumbnailIndex(
    String personId,
    int thumbnailIndex,
  ) async {
    final person = await _repository.setThumbnailIndex(
      personId,
      thumbnailIndex,
    );
    await reload();
    return person;
  }
}

/// 人物データのプロバイダー
final personViewModelProvider =
    AsyncNotifierProvider<PersonViewModel, List<PersonModel>>(
      PersonViewModel.new,
    );
