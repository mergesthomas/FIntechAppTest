import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../entities/market_asset.dart';

abstract class MarketRepository {
  Future<Either<Failure, MarketAsset>> getAsset(
    Currency currency, {
    ChartPeriod period = ChartPeriod.oneDay,
  });

  Future<Either<Failure, PriceSeries>> getChart(
    Currency currency,
    ChartPeriod period,
  );
}
