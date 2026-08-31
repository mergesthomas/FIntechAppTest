import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/market_asset.dart';
import '../entities/market_tick.dart';
import '../repositories/market_repository.dart';

final class GetMarketAsset
    implements UseCase<MarketAsset, ({Currency currency, ChartPeriod period})> {
  GetMarketAsset(this._requireSession, this._market);

  final RequireSession _requireSession;
  final MarketRepository _market;

  @override
  Future<Either<Failure, MarketAsset>> call(
    ({Currency currency, ChartPeriod period}) params,
  ) async {
    final session = await _requireSession(const NoParams());
    return session.fold(
      Either.left,
      (_) => _market.getAsset(params.currency, period: params.period),
    );
  }
}

final class GetPriceChart
    implements
        UseCase<PriceSeries, ({Currency currency, ChartPeriod period})> {
  GetPriceChart(this._requireSession, this._market);

  final RequireSession _requireSession;
  final MarketRepository _market;

  @override
  Future<Either<Failure, PriceSeries>> call(
    ({Currency currency, ChartPeriod period}) params,
  ) async {
    final session = await _requireSession(const NoParams());
    return session.fold(
      Either.left,
      (_) => _market.getChart(params.currency, params.period),
    );
  }
}

final class GetCandleChart
    implements
        UseCase<CandleSeries, ({Currency currency, CandleInterval interval})> {
  GetCandleChart(this._requireSession, this._market);

  final RequireSession _requireSession;
  final MarketRepository _market;

  @override
  Future<Either<Failure, CandleSeries>> call(
    ({Currency currency, CandleInterval interval}) params,
  ) async {
    final session = await _requireSession(const NoParams());
    return session.fold(
      Either.left,
      (_) => _market.getCandles(params.currency, params.interval),
    );
  }
}

final class WatchMarketTicks {
  WatchMarketTicks(this._requireSession, this._market);

  final RequireSession _requireSession;
  final MarketRepository _market;

  Stream<Either<Failure, MarketTick>> call(Currency currency) {
    return _market.watchTicks(currency).asyncMap((tick) async {
      final session = await _requireSession(const NoParams());
      return session.fold(
        Either.left,
        (_) => Either<Failure, MarketTick>.right(tick),
      );
    });
  }
}
