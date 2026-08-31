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
///
/// One slow hill plus seeded noise — not a repeating 5-sample sawtooth.
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
  if (last == Decimal.zero) {
    return List.filled(count, Decimal.zero);
  }
  final seed = _digitSeed(last);
  final n = count <= 1 ? 1 : count - 1;
  return [
    for (var i = 0; i < count; i++)
      last + _syntheticDelta(i: i, n: n, last: last, seed: seed),
  ];
}

int _digitSeed(Decimal last) {
  final digits = last.toString().replaceAll(RegExp(r'[^0-9]'), '');
  var hash = 0;
  for (final unit in digits.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

Decimal _syntheticDelta({
  required int i,
  required int n,
  required Decimal last,
  required int seed,
}) {
  final arch = (Decimal.fromInt(4 * i * (n - i)) / Decimal.fromInt(n * n))
      .toDecimal(scaleOnInfinitePrecision: 12);
  final bump = last * Decimal.parse('0.03') * (arch - Decimal.parse('0.5'));
  final drift = (last * Decimal.parse('0.01') * Decimal.fromInt(i) /
          Decimal.fromInt(n + 1))
      .toDecimal(scaleOnInfinitePrecision: 12);
  final noise = (last *
          Decimal.parse('0.004') *
          Decimal.fromInt(((i * 17 + seed) % 11) - 5) /
          Decimal.fromInt(5))
      .toDecimal(scaleOnInfinitePrecision: 12);
  return bump + drift + noise;
}

Decimal seriesChangeRatio(List<Decimal> closes) {
  if (closes.length < 2 || closes.first == Decimal.zero) {
    return Decimal.zero;
  }
  return ((closes.last - closes.first) / closes.first).toDecimal(
    scaleOnInfinitePrecision: 8,
  );
}
