import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/repositories/market_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';

void main() {
  test('market asset stays stale on the fixture feed', () async {
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final asset = await repo.getAsset(Currency.btc);
    expect(asset.getRight().toNullable()?.freshness, QuoteFreshness.stale);
    expect(asset.getRight().toNullable()?.chart.period, ChartPeriod.oneDay);
    expect(asset.getRight().toNullable()?.chart.closes.length, greaterThan(1));
  });

  test('getCandles returns synthetic OHLCV on the fixture feed', () async {
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final candles = await repo.getCandles(Currency.btc, CandleInterval.h1);
    final series = candles.getRight().toNullable();
    expect(series?.interval, CandleInterval.h1);
    expect(series?.candles.length, greaterThan(1));
    expect(series?.freshness, QuoteFreshness.stale);
  });
}
