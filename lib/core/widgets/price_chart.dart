import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../chart/chart_layout.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

const _markerRadius = 5.0;
const _chartPad = 5.0;

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
    if (!listEquals(oldWidget.points, widget.points) ||
        !listEquals(oldWidget.times, widget.times)) {
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
      chartIndexAt(
        count: widget.points.length,
        width: size.width,
        dx: local.dx,
      ),
    );
  }

  void _clear() => _setIndex(null);

  void _clearIfNotMouse(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) {
      _clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return SizedBox(height: widget.height);
    }
    final scheme = Theme.of(context).colorScheme;
    final up = widget.points.last >= widget.points.first;
    final line = up ? scheme.tertiary : scheme.error;
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
              final ys = chartUnitYs(widget.points);
              final selected = _index;
              final point =
                  selected == null || selected < 0 || selected >= ys.length
                      ? null
                      : _pointOnChart(ys, size, selected);
              return MouseRegion(
                onHover: (event) => _selectAt(event.localPosition, size),
                onExit: (_) => _clear(),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown:
                      (event) => _selectAt(event.localPosition, size),
                  onPointerMove: (event) {
                    if (event.down) {
                      _selectAt(event.localPosition, size);
                    }
                  },
                  onPointerUp: _clearIfNotMouse,
                  onPointerCancel: (_) => _clear(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: size,
                        painter: _PriceChartPainter(
                          points: widget.points,
                          ys: ys,
                          line: line,
                          fill: line.withValues(alpha: 0.08),
                        ),
                      ),
                      if (point != null)
                        Positioned.fill(
                          child: _ChartScrubMarker(
                            point: point,
                            height: size.height,
                            line: line,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChartScrubMarker extends StatelessWidget {
  const _ChartScrubMarker({
    required this.point,
    required this.height,
    required this.line,
  });

  final Offset point;
  final double height;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      key: const Key('chart_scrub_marker'),
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: point.dx - 0.5,
          top: 0,
          width: 1,
          height: height,
          child: ColoredBox(color: scheme.onSurface.withValues(alpha: 0.45)),
        ),
        Positioned(
          left: point.dx - _markerRadius,
          top: point.dy - _markerRadius,
          width: _markerRadius * 2,
          height: _markerRadius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
              border: Border.all(color: line, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

Offset _pointOnChart(List<double> ys, Size size, int index) {
  final last = ys.length - 1;
  final x = last <= 0 ? 0.0 : size.width * index / last;
  final y = _chartPad + (size.height - 2 * _chartPad) * (1 - ys[index]);
  return Offset(x, y);
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.points,
    required this.ys,
    required this.line,
    required this.fill,
  });

  final List<Decimal> points;
  final List<double> ys;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (ys.length < 2) {
      return;
    }
    Offset at(int i) => _pointOnChart(ys, size, i);

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < ys.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final area =
        Path.from(path)
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
