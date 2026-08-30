import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.points,
    this.height = 180,
  });

  final List<Decimal> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(height: height);
    }
    final up = points.last >= points.first;
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _PriceChartPainter(
        points: points,
        line: up ? AppColors.accent : AppColors.danger,
        fill: (up ? AppColors.accent : AppColors.danger).withValues(alpha: 0.18),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.points,
    required this.line,
    required this.fill,
  });

  final List<Decimal> points;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => double.parse(p.toString())).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs() < 0.0001 ? 1.0 : max - min;
    Offset at(int i) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - min) / span) * size.height;
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.line != line;
}
