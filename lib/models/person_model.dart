import 'dart:convert';
import 'package:equatable/equatable.dart';

/// 人物データモデル
///
/// 名前、写真パス（最大5枚）、サムネイルに使用する写真のインデックスを保持する。
class PersonModel extends Equatable {
  /// 一意のID（UUID）
  final String id;

  /// 人物の名前
  final String name;

  /// 写真のファイルパス一覧（最大5枚）
  final List<String> photoPaths;

  /// サムネイルに使用する写真のインデックス（photoPaths内）
  final int thumbnailIndex;

  /// 写真の最大枚数
  static const int maxPhotos = 5;

  const PersonModel({
    required this.id,
    required this.name,
    this.photoPaths = const [],
    this.thumbnailIndex = 0,
  });

  /// サムネイル写真のパスを取得する（写真がない場合はnull）
  String? get thumbnailPath {
    if (photoPaths.isEmpty) return null;
    final index = thumbnailIndex.clamp(0, photoPaths.length - 1);
    return photoPaths[index];
  }

  /// 写真を追加できるかどうか
  bool get canAddPhoto => photoPaths.length < maxPhotos;

  /// コピーメソッド
  PersonModel copyWith({
    String? id,
    String? name,
    List<String>? photoPaths,
    int? thumbnailIndex,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPaths: photoPaths ?? this.photoPaths,
      thumbnailIndex: thumbnailIndex ?? this.thumbnailIndex,
    );
  }

  /// JSONマップに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoPaths': photoPaths,
      'thumbnailIndex': thumbnailIndex,
    };
  }

  /// JSONマップから生成
  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      photoPaths: List<String>.from(json['photoPaths'] as List),
      thumbnailIndex: json['thumbnailIndex'] as int? ?? 0,
    );
  }

  /// JSONリストをエンコード
  static String encodeList(List<PersonModel> persons) {
    return jsonEncode(persons.map((p) => p.toJson()).toList());
  }

  /// JSONリストをデコード
  static List<PersonModel> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => PersonModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  List<Object?> get props => [id, name, photoPaths, thumbnailIndex];
}
