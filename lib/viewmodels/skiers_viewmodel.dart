import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skier_model.dart';
import 'package:uuid/uuid.dart';

class SkierViewModel extends Notifier<List<SkierModel>> {
  @override
  List<SkierModel> build() {
    return [];
  }

  void addSkier(String name, String imagePath, List<double> features) {
    final newSkier = SkierModel(
      id: const Uuid().v4(),
      name: name,
      referenceImagePath: imagePath,
      colorFeatures: features,
    );
    state = [...state, newSkier];
  }

  SkierModel? findMatchingSkier(List<double> detectedFeatures) {
    // TODO: Implement cosmetic similarity comparison
    // For now, return the first one if available
    if (state.isNotEmpty) return state.first;
    return null;
  }
}

final skierViewModelProvider =
    NotifierProvider<SkierViewModel, List<SkierModel>>(SkierViewModel.new);
