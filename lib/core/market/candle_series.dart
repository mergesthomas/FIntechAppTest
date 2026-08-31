import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'candle_interval.dart';
import 'quote_freshness.dart';

final class OhlcvCandle extends Equatable {
  const OhlcvCandle({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime openTime;
  final Decimal open;
  final Decimal high;
  final Decimal low;
  final Decimal close;
  final Decimal volume;

  bool get isBullish => close >= open;

  Decimal get body {
    final delta = close - open;
    return delta < Decimal.zero ? -delta : delta;
  }

  Decimal get upperWick {
    final top = open > close ? open : close;
    return high - top;
  }

  Decimal get lowerWick {
    final bottom = open < close ? open : close;
    return bottom - low;
  }

  Decimal get range => high - low;

  /// Body is at most 5% of the full range (classic doji).
  bool get isDoji {
    if (range <= Decimal.zero) {
      return true;
    }
    return body * Decimal.fromInt(20) <= range;
  }

  /// Small body near the high, lower wick at least 2× body.
  bool get isHammer {
    if (body <= Decimal.zero) {
      return false;
    }
    return lowerWick >= body * Decimal.fromInt(2) && upperWick <= body;
  }

  /// Small body near the low, upper wick at least 2× body.
  bool get isInvertedHammer {
    if (body <= Decimal.zero) {
      return false;
    }
    return upperWick >= body * Decimal.fromInt(2) && lowerWick <= body;
  }

  /// Bearish inverted-hammer shape (long upper wick).
  bool get isShootingStar => isInvertedHammer && close < open;

  OhlcvCandle applyPrice(Decimal price) {
    return OhlcvCandle(
      openTime: openTime,
      open: open,
      high: high > price ? high : price,
      low: low < price ? low : price,
      close: price,
      volume: volume,
    );
  }

  @override
  List<Object?> get props => [openTime, open, high, low, close, volume];
}

final class CandleSeries extends Equatable {
  const CandleSeries({
    required this.interval,
    required this.candles,
    required this.freshness,
  });

  final CandleInterval interval;
  final List<OhlcvCandle> candles;
  final QuoteFreshness freshness;

  OhlcvCandle? get latest => candles.isEmpty ? null : candles.last;

  CandleSeries copyWith({
    CandleInterval? interval,
    List<OhlcvCandle>? candles,
    QuoteFreshness? freshness,
  }) {
    return CandleSeries(
      interval: interval ?? this.interval,
      candles: candles ?? this.candles,
      freshness: freshness ?? this.freshness,
    );
  }

  /// Updates the forming candle, or opens a new one after the interval rolls.
  CandleSeries applyTick({
    required Decimal price,
    required DateTime at,
  }) {
    if (candles.isEmpty) {
      return this;
    }
    final open = candleOpenTime(at, interval);
    final last = candles.last;
    if (open.isAtSameMomentAs(last.openTime)) {
      final next = List<OhlcvCandle>.of(candles);
      next[next.length - 1] = last.applyPrice(price);
      return copyWith(candles: next);
    }
    if (!open.isAfter(last.openTime)) {
      return this;
    }
    final high = price > last.close ? price : last.close;
    final low = price < last.close ? price : last.close;
    return copyWith(
      candles: [
        ...candles,
        OhlcvCandle(
          openTime: open,
          open: last.close,
          high: high,
          low: low,
          close: price,
          volume: Decimal.zero,
        ),
      ],
    );
  }

  @override
  List<Object?> get props => [interval, candles, freshness];
}

/// Deterministic OHLCV for tests and offline fallback. Decimal only.
///
/// Last four candles are classic patterns (doji, hammer, inverted hammer,
/// shooting star) so wick/body proportions stay accurate.
CandleSeries syntheticCandleSeries({
  required Decimal last,
  required CandleInterval interval,
  required DateTime now,
  QuoteFreshness freshness = QuoteFreshness.stale,
  int count = 240,
}) {
  final end = candleOpenTime(now, interval);
  if (last == Decimal.zero) {
    return CandleSeries(
      interval: interval,
      freshness: freshness,
      candles: [
        for (var i = 0; i < count; i++)
          OhlcvCandle(
            openTime: end.subtract(interval.duration * (count - 1 - i)),
            open: Decimal.zero,
            high: Decimal.zero,
            low: Decimal.zero,
            close: Decimal.zero,
            volume: Decimal.zero,
          ),
      ],
    );
  }
  final unit = last * Decimal.parse('0.002');
  final wick = last * Decimal.parse('0.0015');
  final volumeUnit = last * Decimal.parse('0.4');
  final candles = <OhlcvCandle>[
    for (var i = 0; i < count; i++)
      _syntheticAt(
        index: i,
        count: count,
        last: last,
        unit: unit,
        wick: wick,
        volumeUnit: volumeUnit,
        end: end,
        interval: interval,
      ),
  ];
  if (count >= 4) {
    final base = count >= 5 ? candles[count - 5].close : last;
    candles[count - 4] = _doji(
      openTime: candles[count - 4].openTime,
      ref: base,
    );
    candles[count - 3] = _hammer(
      openTime: candles[count - 3].openTime,
      ref: candles[count - 4].close,
    );
    candles[count - 2] = _invertedHammer(
      openTime: candles[count - 2].openTime,
      ref: candles[count - 3].close,
    );
    candles[count - 1] = _shootingStar(
      openTime: candles[count - 1].openTime,
      ref: candles[count - 2].close,
    );
  }
  return CandleSeries(
    interval: interval,
    candles: candles,
    freshness: freshness,
  );
}

OhlcvCandle _syntheticAt({
  required int index,
  required int count,
  required Decimal last,
  required Decimal unit,
  required Decimal wick,
  required Decimal volumeUnit,
  required DateTime end,
  required CandleInterval interval,
}) {
  final prevOffset = (index == 0 ? 0 : index - 1) % 5 - 2;
  final offset = index % 5 - 2;
  final open = last + unit * Decimal.fromInt(prevOffset);
  final close = last + unit * Decimal.fromInt(offset);
  final top = open > close ? open : close;
  final bottom = open < close ? open : close;
  final sign = ((index * 13) % 7) - 3;
  final extra = wick * Decimal.fromInt(sign.abs() + 1);
  return OhlcvCandle(
    openTime: end.subtract(interval.duration * (count - 1 - index)),
    open: open,
    high: top + extra,
    low: bottom - extra,
    close: close,
    volume: volumeUnit * Decimal.fromInt((index % 9) + 1),
  );
}

OhlcvCandle _doji({
  required DateTime openTime,
  required Decimal ref,
}) {
  final range = ref * Decimal.parse('0.012');
  final body = ref * Decimal.parse('0.0002');
  return OhlcvCandle(
    openTime: openTime,
    open: ref,
    high: ref + range,
    low: ref - range,
    close: ref + body,
    volume: ref * Decimal.parse('0.5'),
  );
}

OhlcvCandle _hammer({
  required DateTime openTime,
  required Decimal ref,
}) {
  final body = ref * Decimal.parse('0.002');
  final lower = body * Decimal.fromInt(3);
  final open = ref;
  final close = ref + body;
  return OhlcvCandle(
    openTime: openTime,
    open: open,
    high: close + body * Decimal.parse('0.2'),
    low: open - lower,
    close: close,
    volume: ref * Decimal.parse('0.8'),
  );
}

OhlcvCandle _invertedHammer({
  required DateTime openTime,
  required Decimal ref,
}) {
  final body = ref * Decimal.parse('0.002');
  final upper = body * Decimal.fromInt(3);
  final open = ref;
  final close = ref + body;
  return OhlcvCandle(
    openTime: openTime,
    open: open,
    high: close + upper,
    low: open - body * Decimal.parse('0.2'),
    close: close,
    volume: ref * Decimal.parse('0.7'),
  );
}

OhlcvCandle _shootingStar({
  required DateTime openTime,
  required Decimal ref,
}) {
  final body = ref * Decimal.parse('0.002');
  final upper = body * Decimal.fromInt(3);
  final open = ref;
  final close = ref - body;
  return OhlcvCandle(
    openTime: openTime,
    open: open,
    high: open + upper,
    low: close - body * Decimal.parse('0.2'),
    close: close,
    volume: ref * Decimal.parse('0.9'),
  );
}
