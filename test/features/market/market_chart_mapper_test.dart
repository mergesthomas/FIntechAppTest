import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/candle_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/features/market/presentation/widgets/market_chart_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapper is newest-first and preserves OHLC strings', () {
    final series = CandleSeries(
      interval: CandleInterval.m15,
      freshness: QuoteFreshness.stale,
      candles: [
        OhlcvCandle(
          openTime: DateTime.utc(2026, 1, 1, 10),
          open: Decimal.parse('100.50'),
          high: Decimal.parse('110'),
          low: Decimal.parse('95'),
          close: Decimal.parse('105.25'),
          volume: Decimal.parse('12.5'),
        ),
        OhlcvCandle(
          openTime: DateTime.utc(2026, 1, 1, 10, 15),
          open: Decimal.parse('105.25'),
          high: Decimal.parse('106'),
          low: Decimal.parse('104'),
          close: Decimal.parse('104.5'),
          volume: Decimal.parse('8'),
        ),
      ],
    );
    final mapped = toLibraryCandles(series, showVolume: true);
    expect(mapped, hasLength(2));
    expect(mapped.first.date, DateTime.utc(2026, 1, 1, 10, 15));
    expect(mapped.first.close.toString(), '104.5');
    expect(mapped.last.open.toString(), '100.5');
    expect(mapped.last.volume.toString(), '12.5');
  });

  test('volume toggle zeros library volume without changing OHLC', () {
    final series = syntheticCandleSeries(
      last: Decimal.parse('20'),
      interval: CandleInterval.h1,
      now: DateTime.utc(2026, 1, 1),
    );
    final hidden = toLibraryCandles(series, showVolume: false);
    expect(hidden.every((candle) => candle.volume == 0), isTrue);
    expect(hidden.first.high, greaterThan(0));
  });
}
