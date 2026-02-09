import 'package:equatable/equatable.dart';

class SkierModel extends Equatable {
  final String id;
  final String name;
  final String referenceImagePath;
  final List<double> colorFeatures; // Simplified color features

  const SkierModel({
    required this.id,
    required this.name,
    required this.referenceImagePath,
    required this.colorFeatures,
  });

  @override
  List<Object?> get props => [id, name, referenceImagePath, colorFeatures];
}
