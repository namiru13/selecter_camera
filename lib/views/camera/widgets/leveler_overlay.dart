import 'package:flutter/material.dart';
import '../../../services/sensor_service.dart';

/// 水準器を表示するレイヤー
class LevelerOverlay extends StatelessWidget {
  final SensorService sensorService;

  const LevelerOverlay({super.key, required this.sensorService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SensorData>(
      valueListenable: sensorService.sensorData,
      builder: (context, data, child) {
        return RepaintBoundary(
          child: CustomPaint(
            painter: LevelerPainter(
              roll: data.roll,
              pitch: data.pitch,
              isLevel: data.isLevel,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class LevelerPainter extends CustomPainter {
  final double roll; // 左右の傾き (radian)
  final double pitch; // 前後の傾き (radian)
  final bool isLevel;

  LevelerPainter({
    required this.roll,
    required this.pitch,
    required this.isLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final color = isLevel ? Colors.greenAccent : Colors.white;
    const strokeWidth = 2.0;
    const outlineWidth = 1.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final outlinePaint = Paint()
      ..color = Colors.black.withAlpha(128)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + (outlineWidth * 2);

    // 1. 中央の基準十字線 (静止)
    _drawCrosshair(canvas, center, outlinePaint, paint);

    // 2. 移動する水平線
    // Roll で回転させ、Pitch で上下（あるいは感度に応じて）移動させる
    // ここでは、Roll はカメラの水平を保つための回転、Pitch は前後の傾き（上下の移動）として表現

    _drawMovingLevelScale(canvas, size, center, outlinePaint, paint);
  }

  void _drawCrosshair(Canvas canvas, Offset center, Paint outline, Paint fill) {
    const length = 40.0;
    const gap = 10.0;

    // 水平方向
    canvas.drawLine(
      center - const Offset(length, 0),
      center - const Offset(gap, 0),
      outline,
    );
    canvas.drawLine(
      center + const Offset(gap, 0),
      center + const Offset(length, 0),
      outline,
    );
    canvas.drawLine(
      center - const Offset(length, 0),
      center - const Offset(gap, 0),
      fill,
    );
    canvas.drawLine(
      center + const Offset(gap, 0),
      center + const Offset(length, 0),
      fill,
    );

    // 垂直方向
    canvas.drawLine(
      center - const Offset(0, length),
      center - const Offset(0, gap),
      outline,
    );
    canvas.drawLine(
      center + const Offset(0, gap),
      center + const Offset(0, length),
      outline,
    );
    canvas.drawLine(
      center - const Offset(0, length),
      center - const Offset(0, gap),
      fill,
    );
    canvas.drawLine(
      center + const Offset(0, gap),
      center + const Offset(0, length),
      fill,
    );
  }

  void _drawMovingLevelScale(
    Canvas canvas,
    Size size,
    Offset center,
    Paint outline,
    Paint fill,
  ) {
    canvas.save();

    // 中心を基準に移動・回転
    canvas.translate(center.dx, center.dy);

    // Roll に基づく回転
    // デバイスの傾きと逆方向に回して水平を保つ
    canvas.rotate(-roll);

    const levelWidth = 100.0;

    // 水平線の描画
    canvas.drawLine(
      const Offset(-levelWidth, 0),
      const Offset(levelWidth, 0),
      outline,
    );
    canvas.drawLine(
      const Offset(-levelWidth, 0),
      const Offset(levelWidth, 0),
      fill,
    );

    // 左右の目盛り（少し垂直な線を入れると分かりやすい）
    const tickHeight = 10.0;
    canvas.drawLine(
      const Offset(-levelWidth, -tickHeight),
      const Offset(-levelWidth, tickHeight),
      outline,
    );
    canvas.drawLine(
      const Offset(levelWidth, -tickHeight),
      const Offset(levelWidth, tickHeight),
      outline,
    );
    canvas.drawLine(
      const Offset(-levelWidth, -tickHeight),
      const Offset(-levelWidth, tickHeight),
      fill,
    );
    canvas.drawLine(
      const Offset(levelWidth, -tickHeight),
      const Offset(levelWidth, tickHeight),
      fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LevelerPainter oldDelegate) {
    return oldDelegate.roll != roll ||
        oldDelegate.pitch != pitch ||
        oldDelegate.isLevel != isLevel;
  }
}
