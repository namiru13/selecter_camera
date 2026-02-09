import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:selecter_camera/viewmodels/skiers_viewmodel.dart'; // Adjust package name

void main() {
  test('SkierViewModel adds skier correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final viewModel = container.read(skierViewModelProvider.notifier);

    viewModel.addSkier('Test Skier', 'path/to/image', [1.0, 0.0, 0.0]);

    final skiers = container.read(skierViewModelProvider);
    expect(skiers.length, 1);
    expect(skiers.first.name, 'Test Skier');
    expect(skiers.first.referenceImagePath, 'path/to/image');
    expect(skiers.first.colorFeatures, [1.0, 0.0, 0.0]);
  });
}
