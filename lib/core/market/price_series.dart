import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'quote_freshness.dart';

enum ChartPeriod { oneDay, oneWeek, oneMonth, oneYear, all }

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
/// Shape is seeded by [seedKey] (ticker) and [changeRatio] (24h). First and
/// last closes match that move so every sparkline is not the same hill.
List<Decimal> syntheticCloses({
  required Decimal last,
  required ChartPeriod period,
  String seedKey = '',
  Decimal? changeRatio,
}) {
  final count = syntheticPointCount(period);
  if (last == Decimal.zero) {
    return List.filled(count, Decimal.zero);
  }
  final n = count <= 1 ? 1 : count - 1;
  final seed = _keySeed(seedKey, last);
  final change = changeRatio ?? Decimal.zero;
  final denom = Decimal.one + change;
  final start =
      denom == Decimal.zero
          ? last
          : (last / denom).toDecimal(scaleOnInfinitePrecision: 16);
  final peak = 1 + seed % (n <= 1 ? 1 : n - 1);
  final hill = seed.isEven ? 1 : -1;
  final easeKind = seed % 3;
  final intensity = _bumpIntensity(change);
  return [
    for (var i = 0; i < count; i++)
      _syntheticClose(
        i: i,
        n: n,
        last: last,
        start: start,
        seed: seed,
        peak: peak,
        hill: hill,
        easeKind: easeKind,
        intensity: intensity,
      ),
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

int _keySeed(String seedKey, Decimal last) {
  var hash = _digitSeed(last);
  for (final unit in seedKey.codeUnits) {
    hash = (hash * 33 + unit) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

Decimal _bumpIntensity(Decimal change) {
  final abs = change.abs();
  if (abs > Decimal.parse('0.008')) {
    return abs * Decimal.parse('0.55');
  }
  return Decimal.parse('0.012');
}

Decimal _ease(int i, int n, int kind) {
  final t = (Decimal.fromInt(i) / Decimal.fromInt(n)).toDecimal(
    scaleOnInfinitePrecision: 12,
  );
  return switch (kind) {
    1 => t * t,
    2 => t * (Decimal.fromInt(2) - t),
    _ => t,
  };
}

Decimal _tri(int i, int n, int peak) {
  if (i == 0 || i == n || peak <= 0 || peak >= n) {
    return Decimal.zero;
  }
  if (i == peak) {
    return Decimal.one;
  }
  if (i < peak) {
    return (Decimal.fromInt(i) / Decimal.fromInt(peak)).toDecimal(
      scaleOnInfinitePrecision: 12,
    );
  }
  return (Decimal.fromInt(n - i) / Decimal.fromInt(n - peak)).toDecimal(
    scaleOnInfinitePrecision: 12,
  );
}

Decimal _syntheticClose({
  required int i,
  required int n,
  required Decimal last,
  required Decimal start,
  required int seed,
  required int peak,
  required int hill,
  required int easeKind,
  required Decimal intensity,
}) {
  if (i == 0) {
    return start;
  }
  if (i == n) {
    return last;
  }
  final trend = start + (last - start) * _ease(i, n, easeKind);
  final bump =
      last.abs() * intensity * Decimal.fromInt(hill) * _tri(i, n, peak);
  final noise = (last.abs() *
          Decimal.parse('0.002') *
          Decimal.fromInt(((i * 17 + seed) % 11) - 5) /
          Decimal.fromInt(5))
      .toDecimal(scaleOnInfinitePrecision: 12);
  return trend + bump + noise;
}

int syntheticPointCount(ChartPeriod period) {
  return switch (period) {
    ChartPeriod.oneDay => 24,
    ChartPeriod.oneWeek => 28,
    ChartPeriod.oneMonth => 30,
    ChartPeriod.oneYear => 24,
    ChartPeriod.all => 48,
  };
}

Decimal seriesChangeRatio(List<Decimal> closes) {
  if (closes.length < 2 || closes.first == Decimal.zero) {
    return Decimal.zero;
  }
  return ((closes.last - closes.first) / closes.first).toDecimal(
    scaleOnInfinitePrecision: 8,
  );
}
