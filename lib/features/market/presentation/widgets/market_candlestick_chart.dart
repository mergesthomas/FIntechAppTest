import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:candlesticks/candlesticks.dart';

import '../../../../core/market/candle_series.dart';
import 'market_chart_mapper.dart';

class MarketCandlestickChart extends StatefulWidget {
  const MarketCandlestickChart({
    super.key,
    required this.series,
    required this.showVolume,
  });

  final CandleSeries series;
  final bool showVolume;

  @override
  MarketCandlestickChartState createState() => MarketCandlestickChartState();
}

class MarketCandlestickChartState extends State<MarketCandlestickChart>
    with SingleTickerProviderStateMixin {
  static const _defaultWidth = 6.0;
  static const _restIndex = -10.0;

  final CandlesticksController _controller = CandlesticksController();
  late final AnimationController _inertia;
  final VelocityTracker _velocity = VelocityTracker.withKind(
    PointerDeviceKind.touch,
  );

  var _pointers = 0;
  DateTime? _downAt;
  DateTime? _lastTapAt;
  double _lastInertiaX = 0;

  @override
  void initState() {
    super.initState();
    _inertia = AnimationController.unbounded(vsync: this)
      ..addListener(_applyInertia);
  }

  @override
  void didUpdateWidget(covariant MarketCandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.interval != widget.series.interval) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          resetZoom();
        }
      });
    }
  }

  @override
  void dispose() {
    _inertia.dispose();
    _controller.dispose();
    super.dispose();
  }

  void resetZoom() {
    _inertia.stop();
    _controller.setZoom(_defaultWidth);
    _controller.animateTo(_restIndex);
  }

  void _applyInertia() {
    final x = _inertia.value;
    _controller.scrollByPixels(deltaX: x - _lastInertiaX);
    _lastInertiaX = x;
  }

  void _stopInertia() {
    if (_inertia.isAnimating) {
      _inertia.stop();
    }
  }

  void _startInertia(double velocityX) {
    if (velocityX.abs() < 80) {
      return;
    }
    _lastInertiaX = 0;
    _inertia.animateWith(FrictionSimulation(0.135, 0, velocityX));
  }

  CandleSticksStyle _styleFor(ThemeData theme) {
    final scheme = theme.colorScheme;
    final bull = scheme.tertiary;
    final bear = scheme.error;
    final axis = scheme.onSurfaceVariant;
    final grid = scheme.outline.withValues(alpha: 0.35);
    final background = theme.scaffoldBackgroundColor;
    if (scheme.brightness == Brightness.dark) {
      return CandleSticksStyle.dark(
        chartBackgroundColor: background,
        gridLineColor: grid,
        axisTextColor: axis,
        candleBullColor: bull,
        candleBearColor: bear,
        volumeBullColor: bull.withValues(alpha: 0.45),
        volumeBearColor: bear.withValues(alpha: 0.45),
        crosshairLineColor: axis,
        ohlcInfoTextColor: axis,
        ohlcInfoBullColor: bull,
        ohlcInfoBearColor: bear,
        priceIndicatorBullBackgroundColor: bull,
        priceIndicatorBearBackgroundColor: bear,
      );
    }
    return CandleSticksStyle.light(
      chartBackgroundColor: background,
      gridLineColor: grid,
      axisTextColor: axis,
      candleBullColor: bull,
      candleBearColor: bear,
      volumeBullColor: bull.withValues(alpha: 0.45),
      volumeBearColor: bear.withValues(alpha: 0.45),
      crosshairLineColor: axis,
      ohlcInfoTextColor: axis,
      ohlcInfoBullColor: bull,
      ohlcInfoBearColor: bear,
      priceIndicatorBullBackgroundColor: bull,
      priceIndicatorBearBackgroundColor: bear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final candles = toLibraryCandles(
      widget.series,
      showVolume: widget.showVolume,
    );
    if (candles.length < 2) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    return Listener(
      onPointerDown: (event) {
        _pointers++;
        _downAt = DateTime.now();
        _stopInertia();
        _velocity.addPosition(event.timeStamp, event.position);
      },
      onPointerMove: (event) {
        _velocity.addPosition(event.timeStamp, event.position);
      },
      onPointerUp: (event) {
        final held =
            _downAt == null
                ? Duration.zero
                : DateTime.now().difference(_downAt!);
        final count = _pointers;
        _pointers = (_pointers - 1).clamp(0, 20);
        if (count != 1 || held > const Duration(milliseconds: 320)) {
          return;
        }
        final now = DateTime.now();
        final lastTap = _lastTapAt;
        if (held < const Duration(milliseconds: 220) &&
            lastTap != null &&
            now.difference(lastTap) < const Duration(milliseconds: 320)) {
          _lastTapAt = null;
          resetZoom();
          return;
        }
        _lastTapAt = now;
        _startInertia(_velocity.getVelocity().pixelsPerSecond.dx);
      },
      onPointerCancel: (_) {
        _pointers = (_pointers - 1).clamp(0, 20);
      },
      child: Candlesticks(
        candles: candles,
        controller: _controller,
        style: _styleFor(theme),
      ),
    );
  }
}
