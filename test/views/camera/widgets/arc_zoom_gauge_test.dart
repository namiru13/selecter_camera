import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selecter_camera/views/camera/widgets/arc_zoom_gauge.dart';

void main() {
  testWidgets('ArcZoomGauge renders with correct zoom text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArcZoomGauge(currentZoom: 1.5, minZoom: 1.0, maxZoom: 5.0),
        ),
      ),
    );

    expect(find.text('1.5x'), findsOneWidget);
  });

  testWidgets('ArcZoomGauge applies rotation', (WidgetTester tester) async {
    const rotationTurns = 0.25;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArcZoomGauge(
            currentZoom: 1.0,
            minZoom: 1.0,
            maxZoom: 5.0,
            rotationTurns: rotationTurns,
          ),
        ),
      ),
    );

    final animatedRotationFinder = find.byType(AnimatedRotation);
    expect(animatedRotationFinder, findsOneWidget);

    final animatedRotation = tester.widget<AnimatedRotation>(
      animatedRotationFinder,
    );
    expect(animatedRotation.turns, rotationTurns);
  });
}
