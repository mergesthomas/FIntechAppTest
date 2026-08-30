import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

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
    final values = points.map((p) => double.parse(p.toString())).toList();
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
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ExploreSparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
