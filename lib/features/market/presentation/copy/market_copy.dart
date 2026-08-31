import '../../../../core/market/candle_interval.dart';

abstract final class MarketCopy {
  static const volume = 'Vol';
  static const resetZoom = 'Reset';

  static String intervalLabel(CandleInterval interval) {
    return switch (interval) {
      CandleInterval.m1 => '1m',
      CandleInterval.m5 => '5m',
      CandleInterval.m15 => '15m',
      CandleInterval.h1 => '1h',
      CandleInterval.h4 => '4h',
      CandleInterval.d1 => '1D',
      CandleInterval.w1 => '1W',
    };
  }
}
