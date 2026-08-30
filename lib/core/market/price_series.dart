import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'quote_freshness.dart';

enum ChartPeriod { oneDay, oneWeek, oneMonth, oneYear }

final class PriceSeries extends Equatable {
  const PriceSeries({
    required this.period,
    required this.closes,
    required this.freshness,
  });

  final ChartPeriod period;
  final List<Decimal> closes;
  final QuoteFreshness freshness;

  PriceSeries copyWith({
    ChartPeriod? period,
    List<Decimal>? closes,
    QuoteFreshness? freshness,
  }) {
    return PriceSeries(
      period: period ?? this.period,
      closes: closes ?? this.closes,
      freshness: freshness ?? this.freshness,
    );
  }

  @override
  List<Object?> get props => [period, closes, freshness];
}

/// Deterministic series for tests and offline fallback. Decimal only.
List<Decimal> syntheticCloses({
  required Decimal last,
  required ChartPeriod period,
}) {
  final count = switch (period) {
    ChartPeriod.oneDay => 24,
    ChartPeriod.oneWeek => 28,
    ChartPeriod.oneMonth => 30,
    ChartPeriod.oneYear => 24,
  };
  final unit = last * Decimal.parse('0.002');
  return [
    for (var i = 0; i < count; i++)
      last + unit * Decimal.fromInt((i % 5) - 2),
  ];
}

Decimal seriesChangeRatio(List<Decimal> closes) {
  if (closes.length < 2 || closes.first == Decimal.zero) {
    return Decimal.zero;
  }
  return ((closes.last - closes.first) / closes.first).toDecimal(
    scaleOnInfinitePrecision: 8,
  );
}
