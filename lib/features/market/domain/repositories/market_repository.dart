import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../entities/market_asset.dart';
import '../entities/market_tick.dart';

abstract class MarketRepository {
  Future<Either<Failure, MarketAsset>> getAsset(
    Currency currency, {
    ChartPeriod period = ChartPeriod.oneDay,
  });

  Future<Either<Failure, PriceSeries>> getChart(
    Currency currency,
    ChartPeriod period,
  );

  Future<Either<Failure, CandleSeries>> getCandles(
    Currency currency,
    CandleInterval interval,
  );

  Stream<MarketTick> watchTicks(Currency currency);
}
