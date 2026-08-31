import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/chart/chart_layout.dart';

class ExploreSparkline extends StatelessWidget {
  const ExploreSparkline({
    super.key,
    required this.points,
    required this.color,
    this.width = 56,
    this.height = 24,
  });

  final List<Decimal> points;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(width: width, height: height);
    }
    return CustomPaint(
      size: Size(width, height),
      painter: _ExploreSparklinePainter(points, color),
    );
  }
}

class _ExploreSparklinePainter extends CustomPainter {
  _ExploreSparklinePainter(this.points, this.color);

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
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ExploreSparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
