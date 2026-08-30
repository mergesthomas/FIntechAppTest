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
    final series = _feed.seriesFor(Currency.btc, chartPeriodOf(period));
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
      Currency.nexo,
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
  Future<Either<Failure, CreditHubTeaser>> getCreditHub() async {
    return Either.right(_local.creditHub());
  }

  @override
  Future<Either<Failure, SavingsHubTeaser>> getSavingsHub() async {
    return Either.right(_local.savingsHub());
  }

  @override
  Future<Either<Failure, List<WatchlistItem>>> getWatchlist() async {
    return Either.right([
      for (final item in _local.watchlist())
        WatchlistItem(
          currency: item.currency,
          displayName: item.displayName,
          price: _feed.usdPrice(item.currency) ?? item.price,
          change24hRatio:
              _feed.quoteFor(item.currency)?.change24h ?? item.change24hRatio,
          sparkline: _feed.seriesFor(item.currency).closes,
          freshness: _feed.quoteFor(item.currency)?.freshness ?? item.freshness,
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
