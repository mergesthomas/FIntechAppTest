import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/ledger/paper_ledger.dart';
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
  })  : _feed = feed,
        _ledger = ledger;

  final HomeLocalDataSource _local;
  final MarketFeed _feed;
  final PaperLedger _ledger;

  @override
  Future<Either<Failure, DashboardOverview>> getOverview({
    required String initials,
    DashboardPeriod period = DashboardPeriod.oneWeek,
  }) async {
    final fixture = _local.overview(initials: initials, period: period);
    final series = await _feed.refreshSeries(
      Currency.btc,
      chartPeriodOf(period),
    );
    final chart = series.closes.length >= 2 ? series.closes : fixture.chart;
    return Either.right(
      DashboardOverview(
        netWorth: _netWorth() ?? fixture.netWorth,
        periodChangeRatio: series.closes.length >= 2
            ? seriesChangeRatio(series.closes)
            : fixture.periodChangeRatio,
        period: period,
        chart: chart,
        freshness: _feed.connection,
        initials: initials,
      ),
    );
  }

  Money? _netWorth() {
    var total = Decimal.zero;
    var priced = false;
    const books = LedgerBook.values;
    const currencies = [
      Currency.btc,
      Currency.usdc,
      Currency.eurx,
      Currency.usd,
      Currency.usdt,
      Currency.eth,
    ];
    for (final book in books) {
      for (final currency in currencies) {
        final held = _ledger.balance(book, currency);
        if (held.amount == Decimal.zero) {
          continue;
        }
        final price = _feed.usdPrice(currency);
        if (price == null) {
          continue;
        }
        total += held.amount * price.amount;
        priced = true;
      }
    }
    if (!priced) {
      return null;
    }
    return Money.fromDecimal(total, Currency.usd);
  }

  @override
  Future<Either<Failure, List<WatchlistItem>>> getWatchlist() async {
    final items = _local.watchlist();
    final series = await Future.wait([
      for (final item in items)
        _feed.refreshSeries(item.currency, ChartPeriod.oneDay),
    ]);
    return Either.right([
      for (var i = 0; i < items.length; i++)
        WatchlistItem(
          currency: items[i].currency,
          displayName: items[i].displayName,
          price: _feed.usdPrice(items[i].currency) ?? items[i].price,
          change24hRatio: _feed.quoteFor(items[i].currency)?.change24h ??
              items[i].change24hRatio,
          sparkline: series[i].closes,
          freshness: _feed.quoteFor(items[i].currency)?.freshness ??
              items[i].freshness,
        ),
    ]);
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
