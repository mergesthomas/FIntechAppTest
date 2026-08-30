import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
      painter: _SparklinePainter(points),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.points);

  final List<Decimal> points;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.toString()).map(double.parse).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs() < 0.0001 ? 1.0 : max - min;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - min) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}
