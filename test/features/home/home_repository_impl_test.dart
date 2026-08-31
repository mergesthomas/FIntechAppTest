import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/market/market_feed.dart';
import 'package:fintech_app_test/core/market/market_quote.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/home/data/datasources/home_local_datasource.dart';
import 'package:fintech_app_test/features/home/data/repositories/home_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';

void main() {
  test('fixture portfolio is stale, never live', () async {
    final paper = PaperHarness();
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
    );

    final overview = await repo.getOverview(initials: '78');
    final watchlist = await repo.getWatchlist();

    expect(overview.getRight().toNullable()?.freshness, QuoteFreshness.stale);
    expect(
      watchlist.getRight().toNullable()?.every((i) => i.freshness == QuoteFreshness.stale),
      isTrue,
    );
  });

  test('overview and watchlist charts come from refreshSeries', () async {
    final paper = PaperHarness();
    final closes = [
      Decimal.parse('10'),
      Decimal.parse('11'),
      Decimal.parse('12'),
    ];
    final feed = _RefreshFeed(closes: closes);
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: feed,
      ledger: paper.ledger,
    );

    final overview = await repo.getOverview(initials: '78');
    final watchlist = await repo.getWatchlist();

    expect(overview.getRight().toNullable()?.chart, closes);
    expect(
      watchlist.getRight().toNullable()?.every((item) => item.sparkline == closes),
      isTrue,
    );
    expect(feed.refreshCalls, greaterThan(0));
  });
}

final class _RefreshFeed implements MarketFeed {
  _RefreshFeed({required this.closes});

  final List<Decimal> closes;
  var refreshCalls = 0;

  @override
  QuoteFreshness get connection => QuoteFreshness.stale;

  @override
  Stream<MarketQuote> get quotes => Stream<MarketQuote>.empty();

  @override
  MarketQuote? quoteFor(Currency currency) => null;

  @override
  Money? usdPrice(Currency currency) => null;

  @override
  PriceSeries seriesFor(
    Currency currency, [
    ChartPeriod period = ChartPeriod.oneDay,
  ]) {
    return PriceSeries(
      period: period,
      closes: [Decimal.one],
      freshness: QuoteFreshness.stale,
    );
  }

  @override
  Future<PriceSeries> refreshSeries(
    Currency currency,
    ChartPeriod period,
  ) async {
    refreshCalls++;
    return PriceSeries(
      period: period,
      closes: closes,
      freshness: QuoteFreshness.stale,
    );
  }

  @override
  void dispose() {}
}
