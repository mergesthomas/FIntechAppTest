import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/clock/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/fixtures/watchlist_catalog_fixture.dart';
import '../../../../core/ledger/paper_ledger.dart';
import '../../../../core/ledger/portfolio_chart.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

final class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(
    this._local, {
    required MarketFeed feed,
    required PaperLedger ledger,
    AppClock clock = const SystemClock(),
  }) : _feed = feed,
       _ledger = ledger,
       _clock = clock;

  final HomeLocalDataSource _local;
  final MarketFeed _feed;
  final PaperLedger _ledger;
  final AppClock _clock;

  @override
  Future<Either<Failure, DashboardOverview>> getOverview({
    required String initials,
    DashboardPeriod period = DashboardPeriod.oneWeek,
  }) async {
    final fixture = _local.overview(initials: initials, period: period);
    final chartPeriod = chartPeriodOf(period);
    final now = _clock.now().toUtc();
    final lots = _ledger.lots;
    DateTime? firstActivity;
    for (final lot in lots) {
      final at = lot.at.toUtc();
      if (firstActivity == null || at.isBefore(firstActivity)) {
        firstActivity = at;
      }
    }
    final start = chartWindowStart(
      period: chartPeriod,
      end: now,
      firstActivity: firstActivity,
    );
    final held = _ledger.balances(LedgerBook.savings);
    final currencies = <String, Currency>{
      for (final money in held) money.currency.code: money.currency,
      for (final lot in lots) lot.currency.code: lot.currency,
    };
    final seriesByCode = <String, PriceSeries>{};
    for (final currency in currencies.values) {
      seriesByCode[currency.code] = await _feed.refreshSeries(
        currency,
        chartPeriod,
      );
    }
    final times = portfolioSampleTimes(
      start: start,
      end: now,
      count: syntheticPointCount(chartPeriod),
      events: [for (final lot in lots) lot.at],
      includePreStart: period == DashboardPeriod.all,
    );
    final chart = buildPortfolioChart(
      lots: lots,
      balances: held,
      times: times,
      usdRateAt: (currency, at) {
        final live = _feed.usdPrice(currency)?.amount ?? Decimal.one;
        final series = seriesByCode[currency.code];
        if (series == null) {
          return live;
        }
        return seriesRateAt(
          closes: series.closes,
          start: start,
          end: now,
          at: at,
          fallback: live,
        );
      },
    );
    final samples = chart.length >= 2 ? chart : fixture.chart;
    return Either.right(
      DashboardOverview(
        netWorth: _netWorth(held) ?? fixture.netWorth,
        periodChangeRatio:
            samples.length >= 2
                ? seriesChangeRatio([
                  for (final sample in samples) sample.value.amount,
                ])
                : fixture.periodChangeRatio,
        period: period,
        chart: samples,
        freshness: _feed.connection,
        initials: initials,
      ),
    );
  }

  Money? _netWorth(List<Money> held) {
    var total = Decimal.zero;
    var priced = false;
    for (final money in held) {
      final price = _feed.usdPrice(money.currency);
      if (price == null) {
        continue;
      }
      total += money.amount * price.amount;
      priced = true;
    }
    if (!priced) {
      return null;
    }
    return Money.fromDecimal(total, Currency.usd);
  }

  @override
  Future<Either<Failure, List<HoldingItem>>> getHoldings([
    DashboardPeriod period = DashboardPeriod.oneWeek,
  ]) async {
    final chartPeriod = chartPeriodOf(period);
    final now = _clock.now().toUtc();
    final lots = _ledger.lots;
    DateTime? firstActivity;
    for (final lot in lots) {
      final at = lot.at.toUtc();
      if (firstActivity == null || at.isBefore(firstActivity)) {
        firstActivity = at;
      }
    }
    final start = chartWindowStart(
      period: chartPeriod,
      end: now,
      firstActivity: firstActivity,
    );
    final held = [
      for (final money in _ledger.balances(LedgerBook.savings))
        if (_isHolding(money)) money,
    ];
    final items = <HoldingItem>[];
    for (final money in held) {
      final series = await _feed.refreshSeries(money.currency, chartPeriod);
      final quote = _feed.quoteFor(money.currency);
      final rate = _feed.usdPrice(money.currency);
      if (rate == null) {
        continue;
      }
      final qtyStart = quantityAt(current: money, lots: lots, at: start);
      final rateStart = seriesRateAt(
        closes: series.closes,
        start: start,
        end: now,
        at: start,
        fallback: rate.amount,
      );
      final valueNow = money.amount * rate.amount;
      final valueStart = qtyStart * rateStart;
      final change = valueStart == Decimal.zero
          ? Decimal.zero
          : ((valueNow - valueStart) / valueStart).toDecimal(
            scaleOnInfinitePrecision: 8,
          );
      items.add(
        HoldingItem(
          currency: money.currency,
          displayName: _displayName(money.currency),
          quantity: money,
          value: Money.fromDecimal(valueNow, Currency.usd),
          change24hRatio: change,
          sparkline:
              series.closes.length >= 2
                  ? series.closes
                  : syntheticCloses(
                    last: rate.amount,
                    period: chartPeriod,
                    seedKey: money.currency.code,
                    changeRatio: quote?.change24h,
                  ),
          freshness: quote?.freshness ?? _feed.connection,
        ),
      );
    }
    items.sort((a, b) => b.value.amount.compareTo(a.value.amount));
    return Either.right(items);
  }

  @override
  Future<Either<Failure, List<WatchlistItem>>> getWatchlist() async {
    return Either.right(await _hydrate(await _local.watchlist()));
  }

  @override
  Future<Either<Failure, List<WatchlistItem>>> getWatchlistCandidates() async {
    return searchWatchlistCandidates('');
  }

  @override
  Future<Either<Failure, List<WatchlistItem>>> searchWatchlistCandidates(
    String query,
  ) async {
    return Either.right(
      await _hydrate(await _local.searchWatchlistCandidates(query)),
    );
  }

  @override
  Future<Either<Failure, List<WatchlistItem>>> addWatchlistItem(
    Currency currency,
  ) async {
    if (!_local.isWatchable(currency)) {
      return Either.left(const ValidationFailure('watchlist_unknown_asset'));
    }
    final current = await _local.watchlistCodes();
    if (current.contains(currency.code)) {
      return Either.left(const ValidationFailure('watchlist_already_contains'));
    }
    await _local.addWatchlistCode(currency.code);
    return getWatchlist();
  }

  Future<List<WatchlistItem>> _hydrate(List<WatchlistItem> items) async {
    final series = await Future.wait([
      for (final item in items)
        _feed.refreshSeries(item.currency, ChartPeriod.oneDay),
    ]);
    return [for (var i = 0; i < items.length; i++) _merge(items[i], series[i])];
  }

  WatchlistItem _merge(WatchlistItem item, PriceSeries series) {
    final quote = _feed.quoteFor(item.currency);
    if (quote == null) {
      return item;
    }
    return WatchlistItem(
      currency: item.currency,
      displayName: item.displayName,
      price: _feed.usdPrice(item.currency) ?? item.price,
      change24hRatio: quote.change24h,
      sparkline: series.closes.length >= 2 ? series.closes : item.sparkline,
      freshness: quote.freshness,
    );
  }

  @override
  Future<Either<Failure, List<DashboardAlert>>> getAlerts() async {
    return Either.right(await _local.alerts());
  }

  @override
  Future<Either<Failure, Unit>> dismissAlert(String id) async {
    await _local.dismissAlert(id);
    return Either.right(unit);
  }

  @override
  Future<Either<Failure, List<DashboardPromo>>> getPromos() async {
    return Either.right(_local.promos());
  }

  @override
  Future<Either<Failure, List<NewsPreview>>> getNewsPreview() async {
    return Either.right(_local.news());
  }
}

bool _isHolding(Money money) {
  if (!money.isPositive) {
    return false;
  }
  return switch (money.currency.code) {
    'USD' || 'EURx' || 'USDx' || 'GBPx' => false,
    _ => true,
  };
}

String _displayName(Currency currency) {
  for (final coin in WatchlistCatalogFixture.coins) {
    if (coin.code == currency.code) {
      return coin.name;
    }
  }
  return currency.code;
}
