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
}
