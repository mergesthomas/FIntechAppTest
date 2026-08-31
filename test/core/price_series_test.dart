import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('in-memory series is stale and Decimal-only', () {
    final feed = InMemoryMarketFeed();
    final series = feed.seriesFor(Currency.btc, ChartPeriod.oneDay);
    expect(series.freshness, QuoteFreshness.stale);
    expect(series.closes.length, 24);
    expect(series.closes.first, isA<Decimal>());
    expect(seriesChangeRatio(series.closes), isA<Decimal>());
  });

  test('synthetic series is not a repeating 5-sample sawtooth', () {
    final closes = syntheticCloses(
      last: Decimal.parse('100'),
      period: ChartPeriod.oneDay,
    );
    expect(closes.length, 24);
    final repeats = [
      for (var i = 0; i < 5; i++) closes[i] == closes[i + 5],
    ];
    expect(repeats.every((repeat) => repeat), isFalse);
  });

  test('synthetic series keeps range at micro prices', () {
    final closes = syntheticCloses(
      last: Decimal.parse('0.00000282'),
      period: ChartPeriod.oneDay,
    );
    expect(closes.toSet().length, greaterThan(2));
  });
}
