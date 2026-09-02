import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/person_model.dart';

/// AI推論サービスのモック
class AiInferenceService {
  /// 録画中のフレームから推論し、ターゲットの人物を特定する（モック）
  /// 
  /// 登録されている人物リストを受け取り、いずれかが登録されていれば
  /// ID文字列が一番小さい人物のIDを返します。
  Future<String?> predictTargetPerson(List<PersonModel> registeredPersons) async {
    // モック用のダミーの推論遅延
    await Future.delayed(const Duration(milliseconds: 500));

    if (registeredPersons.isEmpty) {
      return null;
    }

    // IDが一番小さい滑走者を返す
    final sortedPersons = List<PersonModel>.from(registeredPersons)
      ..sort((a, b) => a.id.compareTo(b.id));

    return sortedPersons.first.id;
  }
}

final aiInferenceServiceProvider = Provider((ref) => AiInferenceService());