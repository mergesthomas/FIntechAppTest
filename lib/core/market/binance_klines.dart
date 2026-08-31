import 'package:decimal/decimal.dart';

import 'candle_series.dart';

/// Parses Binance kline rows. All OHLC and volume stay strings → [Decimal].
List<OhlcvCandle> parseBinanceKlines(List<dynamic> rows) {
  final candles = <OhlcvCandle>[];
  for (final row in rows) {
    if (row is! List || row.length < 6) {
      continue;
    }
    final openTime = _openTime(row[0]);
    final open = _decimal(row[1]);
    final high = _decimal(row[2]);
    final low = _decimal(row[3]);
    final close = _decimal(row[4]);
    final volume = _decimal(row[5]) ?? Decimal.zero;
    if (openTime == null ||
        open == null ||
        high == null ||
        low == null ||
        close == null) {
      continue;
    }
    final top = open > close ? open : close;
    final bottom = open < close ? open : close;
    candles.add(
      OhlcvCandle(
        openTime: openTime,
        open: open,
        high: high > top ? high : top,
        low: low < bottom ? low : bottom,
        close: close,
        volume: volume,
      ),
    );
  }
  return candles;
}

/// Parses Binance kline rows. Close (index 4) stays a string → [Decimal].
List<Decimal> parseBinanceKlineCloses(List<dynamic> rows) {
  return [for (final candle in parseBinanceKlines(rows)) candle.close];
}

DateTime? _openTime(dynamic value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  return null;
}

Decimal? _decimal(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return Decimal.parse(value);
  }
  return null;
}
