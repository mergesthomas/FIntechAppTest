import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/market_symbols.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/market_tick.dart';
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

  @override
  Future<Either<Failure, CandleSeries>> getCandles(
    Currency currency,
    CandleInterval interval,
  ) async {
    return Either.right(await _feed.refreshCandles(currency, interval));
  }

  @override
  Stream<MarketTick> watchTicks(Currency currency) {
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return const Stream.empty();
    }
    return _feed.quotes.map((quote) {
      if (quote.symbol != symbol) {
        return null;
      }
      final tick = _feed.quoteFor(currency);
      final usd = _feed.usdPrice(currency);
      if (tick == null || usd == null) {
        return null;
      }
      return MarketTick(
        price: usd,
        last: usd.amount,
        change24h: tick.change24h,
        freshness: tick.freshness,
        at: tick.updatedAt,
      );
    }).where((tick) => tick != null).cast<MarketTick>();
  }
}
