import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/chart/chart_layout.dart';
import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/fixtures/news_feed_fixture.dart';
import 'package:fintech_app_test/core/fixtures/watchlist_catalog_fixture.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/candle_series.dart';
import 'package:fintech_app_test/core/market/market_feed.dart';
import 'package:fintech_app_test/core/market/market_quote.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/home/data/datasources/home_local_datasource.dart';
import 'package:fintech_app_test/features/home/data/repositories/home_repository_impl.dart';
import 'package:fintech_app_test/features/home/domain/entities/dashboard.dart';
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
      watchlist.getRight().toNullable()?.every(
        (i) => i.freshness == QuoteFreshness.stale,
      ),
      isTrue,
    );
  });

  test('overview chart is wallet value from seeded buys', () async {
    final clock = MutableClock(DateTime.utc(2026, 8, 31));
    final paper = PaperHarness(clock: clock);
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
      clock: clock,
    );

    final overview = await repo.getOverview(initials: '78');
    final data = overview.getRight().toNullable()!;

    expect(data.chart.length, greaterThanOrEqualTo(2));
    expect(data.chart.last.value, data.netWorth);
    expect(data.chart.last.at, DateTime.utc(2026, 8, 31));
    expect(data.netWorth.amount > Decimal.parse('20000'), isTrue);
  });

  test('ALL chart starts before 1Y because USDC and BTC buys are older', () async {
    final clock = MutableClock(DateTime.utc(2026, 8, 31));
    final paper = PaperHarness(clock: clock);
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
      clock: clock,
    );

    final year = await repo.getOverview(
      initials: '78',
      period: DashboardPeriod.oneYear,
    );
    final all = await repo.getOverview(
      initials: '78',
      period: DashboardPeriod.all,
    );
    final yearChart = year.getRight().toNullable()!.chart;
    final allChart = all.getRight().toNullable()!.chart;

    expect(allChart.first.at.isBefore(yearChart.first.at), isTrue);
    expect(
      allChart.first.value.amount < yearChart.first.value.amount,
      isTrue,
    );
    expect(allChart.last.value, yearChart.last.value);
  });

  test('holdings are BTC DOGE PEPE and 10k USDC from the ledger', () async {
    final paper = PaperHarness();
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
    );

    final holdings = await repo.getHoldings();
    final items = holdings.getRight().toNullable()!;
    expect(
      items.map((item) => item.currency.code),
      ['BTC', 'USDC', 'DOGE', 'PEPE'],
    );
    expect(
      items.firstWhere((item) => item.currency == Currency.usdc).quantity,
      Money.parse('10000.00', Currency.usdc),
    );
    expect(
      items.every((item) => item.freshness == QuoteFreshness.stale),
      isTrue,
    );
  });

  test('watchlist charts come from refreshSeries', () async {
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

    final watchlist = await repo.getWatchlist();

    expect(
      watchlist.getRight().toNullable()?.every(
        (item) => item.sparkline == closes,
      ),
      isTrue,
    );
    expect(feed.refreshCalls, greaterThan(0));
  });

  test('news preview is four Dogecoin fixture stories', () async {
    final paper = PaperHarness();
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
    );

    final news = await repo.getNewsPreview();
    final items = news.getRight().toNullable();

    expect(items, hasLength(NewsFeedFixture.maxItems));
    expect(
      items?.map((item) => item.id),
      NewsFeedFixture.preview().map((item) => item.id),
    );
  });

  test(
    'addWatchlistItem persists and drops the asset from candidates',
    () async {
      final paper = PaperHarness();
      final repo = HomeRepositoryImpl(
        HomeLocalDataSource(InMemorySecureStore()),
        feed: paper.feed,
        ledger: paper.ledger,
      );

      final before = await repo.getWatchlistCandidates();
      expect(
        before.getRight().toNullable()?.any(
          (item) => item.currency == Currency.sol,
        ),
        isTrue,
      );

      final added = await repo.addWatchlistItem(Currency.sol);
      expect(
        added.getRight().toNullable()?.any(
          (item) => item.currency == Currency.sol,
        ),
        isTrue,
      );

      final after = await repo.getWatchlistCandidates();
      expect(
        after.getRight().toNullable()?.any(
          (item) => item.currency == Currency.sol,
        ),
        isFalse,
      );
    },
  );

  test('addWatchlistItem refuses duplicates and unknown assets', () async {
    final paper = PaperHarness();
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
    );

    final duplicate = await repo.addWatchlistItem(Currency.btc);
    expect(duplicate.getLeft().toNullable(), isA<ValidationFailure>());

    final unknown = await repo.addWatchlistItem(Currency.usd);
    expect(unknown.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('candidates are the CMC top 100 minus the default watchlist', () async {
    final paper = PaperHarness();
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
    );

    final candidates = await repo.getWatchlistCandidates();
    final items = candidates.getRight().toNullable();

    expect(items, hasLength(WatchlistCatalogFixture.size - 5));
    expect(items?.first.currency.code, 'USDT');
    expect(
      items?.every(
        (item) =>
            item.freshness == QuoteFreshness.stale &&
            item.sparkline.length >= 2,
      ),
      isTrue,
    );

    final imx = items!.firstWhere((item) => item.currency.code == 'IMX');
    final inj = items.firstWhere((item) => item.currency.code == 'INJ');
    final wif = items.firstWhere((item) => item.currency.code == 'WIF');
    expect(imx.sparkline.last > imx.sparkline.first, isTrue);
    expect(wif.sparkline.last < wif.sparkline.first, isTrue);
    expect(
      chartUnitYs(imx.sparkline),
      isNot(equals(chartUnitYs(inj.sparkline))),
    );
    expect(
      chartUnitYs(imx.sparkline),
      isNot(equals(chartUnitYs(wif.sparkline))),
    );
  });

  test('searchWatchlistCandidates matches ticker or name', () async {
    final paper = PaperHarness();
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
      feed: paper.feed,
      ledger: paper.ledger,
    );

    final byTicker = await repo.searchWatchlistCandidates('bnb');
    expect(
      byTicker.getRight().toNullable()?.map((item) => item.currency.code),
      ['BNB'],
    );

    final byName = await repo.searchWatchlistCandidates('cardano');
    expect(byName.getRight().toNullable()?.map((item) => item.currency.code), [
      'ADA',
    ]);
  });

  test(
    'addWatchlistItem accepts a catalog coin that is not pre-listed',
    () async {
      final paper = PaperHarness();
      final repo = HomeRepositoryImpl(
        HomeLocalDataSource(InMemorySecureStore()),
        feed: paper.feed,
        ledger: paper.ledger,
      );
      const ada = Currency(code: 'ADA', scale: 8);

      final added = await repo.addWatchlistItem(ada);
      expect(
        added.getRight().toNullable()?.any(
          (item) => item.currency.code == 'ADA',
        ),
        isTrue,
      );
    },
  );
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
  MarketQuote? quoteFor(Currency currency) {
    return MarketQuote(
      symbol: currency.code,
      price: Money.parse('10', Currency.usdt),
      change24h: Decimal.zero,
      freshness: QuoteFreshness.stale,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Money? usdPrice(Currency currency) => Money.parse('10', Currency.usd);

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
  CandleSeries candlesFor(
    Currency currency, [
    CandleInterval interval = CandleInterval.m15,
  ]) {
    return syntheticCandleSeries(
      last: Decimal.one,
      interval: interval,
      now: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<CandleSeries> refreshCandles(
    Currency currency,
    CandleInterval interval,
  ) async {
    return candlesFor(currency, interval);
  }

  @override
  void dispose() {}
}
