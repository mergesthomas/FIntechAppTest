enum CandleInterval {
  m1,
  m5,
  m15,
  h1,
  h4,
  d1,
  w1;

  String get binanceCode => switch (this) {
        CandleInterval.m1 => '1m',
        CandleInterval.m5 => '5m',
        CandleInterval.m15 => '15m',
        CandleInterval.h1 => '1h',
        CandleInterval.h4 => '4h',
        CandleInterval.d1 => '1d',
        CandleInterval.w1 => '1w',
      };

  Duration get duration => switch (this) {
        CandleInterval.m1 => const Duration(minutes: 1),
        CandleInterval.m5 => const Duration(minutes: 5),
        CandleInterval.m15 => const Duration(minutes: 15),
        CandleInterval.h1 => const Duration(hours: 1),
        CandleInterval.h4 => const Duration(hours: 4),
        CandleInterval.d1 => const Duration(days: 1),
        CandleInterval.w1 => const Duration(days: 7),
      };

  int get requestLimit => switch (this) {
        CandleInterval.d1 => 365,
        CandleInterval.w1 => 200,
        _ => 500,
      };
}

/// Binance-style UTC open time for [interval] containing [time].
DateTime candleOpenTime(DateTime time, CandleInterval interval) {
  final utc = time.toUtc();
  return switch (interval) {
    CandleInterval.m1 => DateTime.utc(
        utc.year,
        utc.month,
        utc.day,
        utc.hour,
        utc.minute,
      ),
    CandleInterval.m5 => DateTime.utc(
        utc.year,
        utc.month,
        utc.day,
        utc.hour,
        utc.minute - utc.minute % 5,
      ),
    CandleInterval.m15 => DateTime.utc(
        utc.year,
        utc.month,
        utc.day,
        utc.hour,
        utc.minute - utc.minute % 15,
      ),
    CandleInterval.h1 => DateTime.utc(
        utc.year,
        utc.month,
        utc.day,
        utc.hour,
      ),
    CandleInterval.h4 => DateTime.utc(
        utc.year,
        utc.month,
        utc.day,
        utc.hour - utc.hour % 4,
      ),
    CandleInterval.d1 => DateTime.utc(utc.year, utc.month, utc.day),
    CandleInterval.w1 => DateTime.utc(utc.year, utc.month, utc.day).subtract(
        Duration(days: utc.weekday - DateTime.monday),
      ),
  };
}
