import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/depth_book.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/market_symbols.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/market_tick.dart';
import '../../domain/entities/order_book.dart';
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

  @override
  Future<Either<Failure, OrderBook>> getOrderBook(
    Currency currency, {
    int depth = orderBookDefaultDepth,
  }) async {
    final remote = await _feed.refreshDepth(currency);
    final mapped = _mapDepth(remote, currency, depth);
    if (mapped != null) {
      return Either.right(mapped);
    }
    final book = _local.bookFor(currency, depth: depth);
    if (book == null) {
      return Either.left(const ValidationFailure('order_book_unavailable'));
    }
    return Either.right(book);
  }

  @override
  Stream<OrderBook> watchOrderBook(
    Currency currency, {
    int depth = orderBookDefaultDepth,
  }) {
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return const Stream.empty();
    }
    final remote = _mapDepth(_feed.depthFor(currency), currency, depth);
    final fixture =
        remote == null ? _local.bookFor(currency, depth: depth) : null;
    final first = remote ?? fixture;
    return () async* {
      if (first != null) {
        yield first;
      }
      await for (final book in _feed.depths) {
        if (book.symbol != symbol) {
          continue;
        }
        final mapped = _mapDepth(book, currency, depth);
        if (mapped != null) {
          yield mapped;
        }
      }
    }();
  }

  OrderBook? _mapDepth(DepthBook? book, Currency currency, int depth) {
    if (book == null) {
      return null;
    }
    return OrderBook.normalized(
      currency: currency,
      quote: Currency.usdt,
      bids: [
        for (final level in book.bids)
          OrderBookLevel(
            side: OrderBookSide.bid,
            price: level.price,
            size: Money.fromDecimal(level.quantity, currency),
          ),
      ],
      asks: [
        for (final level in book.asks)
          OrderBookLevel(
            side: OrderBookSide.ask,
            price: level.price,
            size: Money.fromDecimal(level.quantity, currency),
          ),
      ],
      freshness: book.freshness,
      updatedAt: book.updatedAt,
      depth: depth,
    );
  }
}
