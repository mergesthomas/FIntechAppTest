import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../chart/chart_layout.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.points,
    this.times,
    this.height = 160,
    this.onScrub,
    this.scrubLabel,
  });

  final List<Decimal> points;
  final List<DateTime>? times;
  final double height;
  final ValueChanged<int?>? onScrub;
  final String? scrubLabel;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int? _index;

  @override
  void didUpdateWidget(covariant PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points || oldWidget.times != widget.times) {
      _index = null;
    }
  }

  void _setIndex(int? index) {
    if (_index == index) {
      return;
    }
    setState(() => _index = index);
    widget.onScrub?.call(index);
  }

  void _selectAt(Offset local, Size size) {
    if (widget.points.length < 2) {
      return;
    }
    _setIndex(
      chartIndexAt(count: widget.points.length, width: size.width, dx: local.dx),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return SizedBox(height: widget.height);
    }
    final scheme = Theme.of(context).colorScheme;
    final up = widget.points.last >= widget.points.first;
    final line = up ? scheme.tertiary : scheme.error;
    final interactive = widget.onScrub != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.scrubLabel != null) ...[
          Text(
            widget.scrubLabel!,
            key: const Key('chart_scrub_label'),
            style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, widget.height);
              final chart = CustomPaint(
                size: size,
                painter: _PriceChartPainter(
                  points: widget.points,
                  line: line,
                  fill: line.withValues(alpha: 0.08),
                  selectedIndex: _index,
                  marker: scheme.onSurface,
                ),
              );
              if (!interactive) {
                return chart;
              }
              return MouseRegion(
                onHover: (event) => _selectAt(event.localPosition, size),
                child: GestureDetector(
                  onTapDown: (details) => _selectAt(details.localPosition, size),
                  onHorizontalDragStart: (details) =>
                      _selectAt(details.localPosition, size),
                  onHorizontalDragUpdate: (details) =>
                      _selectAt(details.localPosition, size),
                  child: chart,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.points,
    required this.line,
    required this.fill,
    required this.selectedIndex,
    required this.marker,
  });

  final List<Decimal> points;
  final Color line;
  final Color fill;
  final int? selectedIndex;
  final Color marker;

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
    final selected = selectedIndex;
    if (selected == null || selected < 0 || selected >= ys.length) {
      return;
    }
    final point = at(selected);
    canvas.drawLine(
      Offset(point.dx, 0),
      Offset(point.dx, size.height),
      Paint()
        ..color = marker.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(point, 3.5, Paint()..color = line);
    canvas.drawCircle(
      point,
      3.5,
      Paint()
        ..color = marker
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.line != line ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.marker != marker;
}
