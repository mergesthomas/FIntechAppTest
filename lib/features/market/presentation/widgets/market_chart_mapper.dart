import 'package:candlesticks/candlesticks.dart';
import 'package:decimal/decimal.dart';

import '../../../../core/market/candle_series.dart';

/// Maps domain [OhlcvCandle] values to the chart library. Newest first.
///
/// Conversion to [double] happens only here — domain stays [Decimal].
List<Candle> toLibraryCandles(
  CandleSeries series, {
  required bool showVolume,
}) {
  final candles = series.candles;
  return [
    for (var i = candles.length - 1; i >= 0; i--)
      Candle(
        date: candles[i].openTime,
        open: _chartDouble(candles[i].open),
        high: _chartDouble(candles[i].high),
        low: _chartDouble(candles[i].low),
        close: _chartDouble(candles[i].close),
        volume: showVolume ? _chartDouble(candles[i].volume) : 0,
      ),
  ];
}

double _chartDouble(Decimal amount) {
  return double.parse(amount.toString());
}
