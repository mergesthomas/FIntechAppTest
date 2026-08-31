import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../chart/chart_layout.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.points,
    this.height = 160,
  });

  final List<Decimal> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(height: height);
    }
    final scheme = Theme.of(context).colorScheme;
    final up = points.last >= points.first;
    final line = up ? scheme.tertiary : scheme.error;
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _PriceChartPainter(
        points: points,
        line: line,
        fill: line.withValues(alpha: 0.08),
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
    final ys = chartUnitYs(points);
    if (ys.length < 2) {
      return;
    }
    Offset at(int i) {
      final x = size.width * i / (ys.length - 1);
      final y = size.height * (1 - ys[i]);
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < ys.length; i++) {
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
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.line != line;
}
