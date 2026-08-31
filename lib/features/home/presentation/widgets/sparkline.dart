import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/chart/chart_layout.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.points, this.height = 48});

  final List<Decimal> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(height: height);
    }
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _SparklinePainter(
        points,
        Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.points, this.color);

  final List<Decimal> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ys = chartUnitYs(points);
    if (ys.length < 2) {
      return;
    }
    final path = Path();
    for (var i = 0; i < ys.length; i++) {
      final x = size.width * i / (ys.length - 1);
      final y = size.height * (1 - ys[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
