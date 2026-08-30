import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/market_local_datasource.dart';

final class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl(
    this._local, {
    required MarketFeed feed,
  }) : _feed = feed;

  final MarketLocalDataSource _local;
  final MarketFeed _feed;

  @override
  Future<Either<Failure, MarketAsset>> getAsset(
    Currency currency, {
    ChartPeriod period = ChartPeriod.oneDay,
  }) async {
    final chart = await _feed.refreshSeries(currency, period);
    final tick = _feed.quoteFor(currency);
    final usd = _feed.usdPrice(currency);
    return Either.right(
      MarketAsset(
        currency: currency,
        name: _local.nameFor(currency),
        price: usd ?? Money.zero(Currency.usd),
        change24h: tick?.change24h ?? Decimal.zero,
        freshness: tick?.freshness ?? _feed.connection,
        chart: chart,
      ),
    );
  }

  @override
  Future<Either<Failure, PriceSeries>> getChart(
    Currency currency,
    ChartPeriod period,
  ) async {
    return Either.right(await _feed.refreshSeries(currency, period));
  }
}
