import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/market_asset.dart';
import '../entities/market_tick.dart';
import '../entities/order_book.dart';
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

Failure? _orderBookDepthFailure(int depth) {
  if (depth < 1 || depth > orderBookMaxDepth) {
    return const ValidationFailure('order_book_depth_invalid');
  }
  return null;
}

final class GetOrderBook
    implements
        UseCase<OrderBook, ({Currency currency, int depth})> {
  GetOrderBook(this._requireSession, this._market);

  final RequireSession _requireSession;
  final MarketRepository _market;

  @override
  Future<Either<Failure, OrderBook>> call(
    ({Currency currency, int depth}) params,
  ) async {
    final depth = _orderBookDepthFailure(params.depth);
    if (depth != null) {
      return Either.left(depth);
    }
    final session = await _requireSession(const NoParams());
    return session.fold(
      Either.left,
      (_) => _market.getOrderBook(params.currency, depth: params.depth),
    );
  }
}

final class WatchOrderBook {
  WatchOrderBook(this._requireSession, this._market);

  final RequireSession _requireSession;
  final MarketRepository _market;

  Stream<Either<Failure, OrderBook>> call(
    ({Currency currency, int depth}) params,
  ) {
    final depth = _orderBookDepthFailure(params.depth);
    if (depth != null) {
      return Stream.value(Either.left(depth));
    }
    return _market
        .watchOrderBook(params.currency, depth: params.depth)
        .asyncMap((book) async {
      final session = await _requireSession(const NoParams());
      return session.fold(
        Either.left,
        (_) => Either<Failure, OrderBook>.right(book),
      );
    });
  }
}

final class SelectOrderBookLevel
    implements
        UseCase<
          BookTicketDraft,
          ({Currency currency, OrderBookSide side, Money price})
        > {
  SelectOrderBookLevel(this._requireSession, this._market);

  final RequireSession _requireSession;
  final MarketRepository _market;

  @override
  Future<Either<Failure, BookTicketDraft>> call(
    ({Currency currency, OrderBookSide side, Money price}) params,
  ) async {
    final session = await _requireSession(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final loaded = await _market.getOrderBook(params.currency);
      return loaded.fold(Either.left, (book) {
        if (book.freshness == QuoteFreshness.disconnected) {
          return Either<Failure, BookTicketDraft>.left(
            const StaleQuoteFailure(),
          );
        }
        final level = book.findLevel(params.side, params.price);
        if (level == null) {
          return Either<Failure, BookTicketDraft>.left(
            const ValidationFailure('book_level_unknown'),
          );
        }
        return Either.right(
          BookTicketDraft(
            currency: book.currency,
            quote: book.quote,
            side: level.side,
            limitPrice: level.price,
            size: level.size,
            freshness: book.freshness,
          ),
        );
      });
    });
  }
}
