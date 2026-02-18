import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class ArcZoomGauge extends StatelessWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final List<double> snapPoints;
  final double rotationTurns;

  const ArcZoomGauge({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    this.snapPoints = const [],
    this.rotationTurns = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.gaugeHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            painter: _ArcDialPainter(
              currentZoom: currentZoom,
              minZoom: minZoom,
              maxZoom: maxZoom,
              snapPoints: snapPoints,
              rotationTurns: rotationTurns,
            ),
            size: Size.infinite,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: AnimatedRotation(
              turns: rotationTurns,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Text(
                "${currentZoom.toStringAsFixed(1)}x",
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: AppConstants.gaugeZoomFontSize,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 4,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcDialPainter extends CustomPainter {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final List<double> snapPoints;
  final double rotationTurns;

  _ArcDialPainter({
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.snapPoints,
    required this.rotationTurns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 2.0);
    final radius = size.height * 1.8;

    // We want to show a visible range of zoom levels around the current zoom.
    // Let's say we show +/- some amount of zoom, or map the whole range to an angle?
    // Mapping whole range to an angle is better for a fixed scale.
    // But for a "dial", usually we map zoom to angle.

    // Let's define the angle range for the arc.
    // ColorOS usually acts like a wheel.
    // Let's say the visible arc is from -40 to +40 degrees.
    // Let's say the visible arc is from -50 to +50 degrees to show more.
    const visibleAngleDeg = AppConstants.gaugeVisibleAngleDeg;
    const visibleAngleRad = visibleAngleDeg * (math.pi / 180.0);

    final paintTick = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Calculate the angle for the current zoom.
    // We want 'currentZoom' to be at -90 degrees (top of the circle, if 0 is right).
    // Actually, in standard canvas, 0 is right, -90 is top.
    // Let's define: Top (-90 deg) is the anchor.
    // A zoom value Z will map to an angle A.
    // We want the tick for Z to be drawn at Angle(Z).
    // But we are rotating the dial so that Angle(currentZoom) = -90.
    // So visual_angle(Z) = Angle(Z) - Angle(currentZoom) - 90 deg.

    // Mapping:
    // Let's scale zoom logarithmically or linearly?
    // Cameras often use linear or log. Let's stick to linear for simplicity unless it feels off.
    // Or we can just space ticks evenly.

    // Let's define a span.
    // If we want the whole range (min to max) to fit in a wide arc (e.g. 120 degrees)?
    // Or do we want infinite scrolling feel?
    // Given min/max are fixed (e.g. 1x to 10x), fitting to a wide arc is good.
    // Let's map minZoom -> -60 deg from center, maxZoom -> +60 deg from center.
    // Center is -90 deg.
    // So minZoom angle = -90 - 60 = -150 deg.
    // MaxZoom angle = -90 + 60 = -30 deg.

    // However, the REQUEST is likely to have the "current zoom" indicator fixed, and the ticks to move.
    // If we use the mapping above, the ticks are fixed in space, and the indicator would move.
    // BUT the previous UI had a moving bar.
    // ColorOS dial: The *scale* moves, the *indicator* is fixed center.
    // So, we need to apply a rotation to the whole system such that `getAngleForZoom(currentZoom)` ends up at -PI/2.

    // Wait, if it's a fixed range (1x to 10x), and we want a dial...
    // If I drag, I want to see the numbers spin.
    // If I am at 1x, 1x is at center. 10x is far right.
    // If I am at 5x, 5x is at center. 1x is left, 10x is right.

    // So let's define an angular spacing per zoom unit?
    // constant `anglePerZoomUnit`.
    // angle(z) = (z - currentZoom) * anglePerZoomUnit - PI/2.
    // This gives the "infinite wheel" feel.

    // Wider spacing for better visibility
    final anglePerUnit = AppConstants.gaugeAnglePerUnitDeg * (math.pi / 180.0);

    // Filter which ticks to draw to avoid drawing everything
    // Visible range is -PI/2 +/- visibleAngleRad/2
    // We want ticks where angle(z) is within this range.

    // Draw Ticks
    // We can iterate through some meaningful steps.
    // Major ticks at integers (1.0, 2.0, 3.0...).
    // Minor ticks in between (0.5 or 0.2).

    // Draw Main Arc Line?
    // ColorOS has a faint arc backing usually.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 - visibleAngleRad / 2,
      visibleAngleRad,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppConstants.gaugeArcStrokeWidth
        ..strokeCap = StrokeCap.round,
      // Apply a mask or gradient fading at ends?
      // Simple arc for now.
    );

    // Draw active arc portion? (From min to current?)
    // In a dial, usually you don't fill the arc like a progress bar, you just show the scale.
    // But request said "transform straight line to arc". The previous one was a filled bar.
    // Maybe a filled arc segment?
    // Let's try to emulate the "Wheel" look first as it's more "ColorOS".

    void drawTick(double zoomVal, bool isMajor, bool isSnap) {
      final angle = (zoomVal - currentZoom) * anglePerUnit - math.pi / 2;

      // Check visibility
      // +/- 40 degrees
      if (angle < -math.pi / 2 - visibleAngleRad / 2 ||
          angle > -math.pi / 2 + visibleAngleRad / 2) {
        return;
      }

      // Calculate opacity based on distance from center
      // Calculate opacity based on distance from center
      final dist = (angle - (-math.pi / 2)).abs();
      // Make opacity fall off only near the edges (last 20%)
      final visibleHalf = visibleAngleRad / 2;
      double opacity = 1.0;
      if (dist > visibleHalf * 0.6) {
        opacity = (1.0 - ((dist - visibleHalf * 0.6) / (visibleHalf * 0.4)))
            .clamp(0.0, 1.0);
      }

      final tickLen = isMajor ? 12.0 : 6.0;
      final tickWidth = isMajor ? 2.0 : 1.0;
      final color = isSnap ? Colors.yellow : Colors.white;

      paintTick
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = tickWidth;

      final p1 = Offset(
        center.dx + (radius - tickLen) * math.cos(angle),
        center.dy + (radius - tickLen) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(p1, p2, paintTick);

      // Only draw text for specific snap points (2, 3, 6, 10)
      // We check if the current zoomVal is close to any snap point
      bool shouldDrawLabel = snapPoints.any((s) => (s - zoomVal).abs() < 0.01);

      if (isMajor && shouldDrawLabel) {
        // Draw text
        final textSpan = TextSpan(
          text: "${zoomVal.toInt()}x",
          style: TextStyle(
            color: Colors.white.withValues(alpha: opacity),
            fontSize: AppConstants.gaugeTickLabelFontSize,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        );
        textPainter.text = textSpan;
        textPainter.layout();

        // Position text inside the tick
        final textRadius = radius - tickLen - 15.0;
        final tp = Offset(
          center.dx + textRadius * math.cos(angle) - textPainter.width / 2,
          center.dy + textRadius * math.sin(angle) - textPainter.height / 2,
        );

        // Rotate text? Or keep upright?
        // Upright is easier to read.

        canvas.save();
        // Translate to text center
        final textCenter =
            tp + Offset(textPainter.width / 2, textPainter.height / 2);
        canvas.translate(textCenter.dx, textCenter.dy);
        // Rotate
        canvas.rotate(rotationTurns * 2 * math.pi);
        // Translate back
        canvas.translate(-textCenter.dx, -textCenter.dy);

        textPainter.paint(canvas, tp);
        canvas.restore();
      }
    }

    // Generate ticks
    // We start from minZoom up to maxZoom
    // Step: 0.1
    for (double z = minZoom; z <= maxZoom; z += 0.5) {
      // 0.5 steps for less clutter
      // Check if it's close to an integer
      bool isInteger = (z % 1.0).abs() < 0.01;
      // Check if it's a snap point
      bool isSnap = snapPoints.any((s) => (s - z).abs() < 0.01);

      drawTick(z, isInteger || isSnap, isSnap);
    }

    // Draw Center Indicator
    // Triangle or line at top center
    final indicatorPaint = Paint()..color = Colors.yellow;
    // Draw a small circle or triangle
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius - 10),
      4.0,
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcDialPainter oldDelegate) {
    return oldDelegate.currentZoom != currentZoom ||
        oldDelegate.minZoom != minZoom ||
        oldDelegate.maxZoom != maxZoom;
  }
}
