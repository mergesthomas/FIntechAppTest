import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/chart/chart_layout.dart';
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

  test('all-period synthetic series is longer than 1Y', () {
    final year = syntheticCloses(
      last: Decimal.parse('100'),
      period: ChartPeriod.oneYear,
    );
    final all = syntheticCloses(
      last: Decimal.parse('100'),
      period: ChartPeriod.all,
    );
    expect(year.length, 24);
    expect(all.length, 48);
  });

  test('synthetic series is not a repeating 5-sample sawtooth', () {
    final closes = syntheticCloses(
      last: Decimal.parse('100'),
      period: ChartPeriod.oneDay,
    );
    expect(closes.length, 24);
    final repeats = [for (var i = 0; i < 5; i++) closes[i] == closes[i + 5]];
    expect(repeats.every((repeat) => repeat), isFalse);
  });

  test('synthetic series keeps range at micro prices', () {
    final closes = syntheticCloses(
      last: Decimal.parse('0.00000282'),
      period: ChartPeriod.oneDay,
    );
    expect(closes.toSet().length, greaterThan(2));
  });

  test('seeded series follow 24h direction and do not share a shape', () {
    final imx = syntheticCloses(
      last: Decimal.parse('1.05'),
      period: ChartPeriod.oneDay,
      seedKey: 'IMX',
      changeRatio: Decimal.parse('0.0190'),
    );
    final inj = syntheticCloses(
      last: Decimal.parse('18.40'),
      period: ChartPeriod.oneDay,
      seedKey: 'INJ',
      changeRatio: Decimal.parse('0.0260'),
    );
    final wif = syntheticCloses(
      last: Decimal.parse('1.42'),
      period: ChartPeriod.oneDay,
      seedKey: 'WIF',
      changeRatio: Decimal.parse('-0.0180'),
    );

    expect(imx.last > imx.first, isTrue);
    expect(inj.last > inj.first, isTrue);
    expect(wif.last < wif.first, isTrue);
    expect(chartUnitYs(imx), isNot(equals(chartUnitYs(inj))));
    expect(chartUnitYs(imx), isNot(equals(chartUnitYs(wif))));
    expect(chartUnitYs(inj), isNot(equals(chartUnitYs(wif))));
  });
}
