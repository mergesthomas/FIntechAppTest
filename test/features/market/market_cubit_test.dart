import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/candle_series.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/market/domain/entities/order_book.dart';
import 'package:fintech_app_test/features/market/domain/repositories/market_repository.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/repositories/market_repository_impl.dart';
import 'package:fintech_app_test/features/market/domain/entities/market_asset.dart';
import 'package:fintech_app_test/features/market/domain/entities/market_tick.dart';
import 'package:fintech_app_test/features/market/domain/usecases/market_usecases.dart';
import 'package:fintech_app_test/features/market/presentation/cubit/market_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late MarketCubit cubit;
  late PaperHarness paper;

  setUp(() {
    auth = MockAuthRepository();
    paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final session = RequireSession(auth);
    cubit = MarketCubit(
      getAsset: GetMarketAsset(session, repo),
      getCandles: GetCandleChart(session, repo),
      watchTicks: WatchMarketTicks(session, repo),
      getOrderBook: GetOrderBook(session, repo),
      watchOrderBook: WatchOrderBook(session, repo),
      selectOrderBookLevel: SelectOrderBookLevel(session, repo),
      code: 'BTC',
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits success with candles', () async {
    await cubit.load();
    expect(cubit.state, isA<MarketSuccess>());
    final success = cubit.state as MarketSuccess;
    expect(success.asset.chart.closes.length, greaterThan(1));
    expect(success.candles.candles.length, greaterThan(1));
    expect(success.candles.interval, CandleInterval.m15);
    expect(success.showVolume, isTrue);
  });

  test('unknown asset emits failure', () async {
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final session = RequireSession(auth);
    final bad = MarketCubit(
      getAsset: GetMarketAsset(session, repo),
      getCandles: GetCandleChart(session, repo),
      watchTicks: WatchMarketTicks(session, repo),
      getOrderBook: GetOrderBook(session, repo),
      watchOrderBook: WatchOrderBook(session, repo),
      selectOrderBookLevel: SelectOrderBookLevel(session, repo),
      code: 'NOPE',
    );
    await bad.load();
    expect(bad.state, isA<MarketFailure>());
    expect(
      (bad.state as MarketFailure).failure,
      isA<ValidationFailure>(),
    );
    await bad.close();
  });

  test('selectInterval keeps the asset and changes candles', () async {
    await cubit.load();
    await cubit.selectInterval(CandleInterval.h1);
    expect(cubit.state, isA<MarketSuccess>());
    expect(
      (cubit.state as MarketSuccess).candles.interval,
      CandleInterval.h1,
    );
    expect(
      (cubit.state as MarketSuccess).asset.chart.period,
      ChartPeriod.oneDay,
    );
  });

  test('toggleVolume flips the volume flag', () async {
    await cubit.load();
    cubit.toggleVolume();
    expect((cubit.state as MarketSuccess).showVolume, isFalse);
    cubit.toggleVolume();
    expect((cubit.state as MarketSuccess).showVolume, isTrue);
  });

  test('live tick updates the forming candle close', () async {
    await cubit.load();
    paper.feed.put(
      paper.feed.quoteFor(Currency.btc)!.copyWith(
        price: Money.parse('80000', Currency.usdt),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final success = cubit.state as MarketSuccess;
    expect(success.candles.latest!.close, Decimal.parse('80000'));
    expect(success.asset.price.amount, Decimal.parse('80000'));
  });

  test('load attaches a stale fixture order book', () async {
    await cubit.load();
    final success = cubit.state as MarketSuccess;
    expect(success.orderBook?.freshness, QuoteFreshness.stale);
    expect(success.orderBook?.bids, isNotEmpty);
  });

  test('selectLevel returns a draft and does not submit', () async {
    await cubit.load();
    final book = (cubit.state as MarketSuccess).orderBook!;
    final draft = await cubit.selectLevel(
      side: OrderBookSide.bid,
      price: book.bids.first.price,
    );
    expect(draft?.limitPrice, book.bids.first.price);
    expect(draft?.freshness, QuoteFreshness.stale);
    expect(cubit.state, isA<MarketSuccess>());
  });

  test('selectLevel refuses a disconnected book', () async {
    final repo = _DisconnectedBookRepo(
      MarketRepositoryImpl(
        const MarketLocalDataSource(),
        feed: paper.feed,
      ),
    );
    final session = RequireSession(auth);
    final disconnected = MarketCubit(
      getAsset: GetMarketAsset(session, repo),
      getCandles: GetCandleChart(session, repo),
      watchTicks: WatchMarketTicks(session, repo),
      getOrderBook: GetOrderBook(session, repo),
      watchOrderBook: WatchOrderBook(session, repo),
      selectOrderBookLevel: SelectOrderBookLevel(session, repo),
      code: 'BTC',
    );
    await disconnected.load();
    final book = (disconnected.state as MarketSuccess).orderBook!;
    expect(book.freshness, QuoteFreshness.disconnected);
    final draft = await disconnected.selectLevel(
      side: OrderBookSide.bid,
      price: book.bids.first.price,
    );
    expect(draft, isNull);
    expect(
      (disconnected.state as MarketSuccess).selectionFailure,
      isA<StaleQuoteFailure>(),
    );
    await disconnected.close();
  });
}

final class _DisconnectedBookRepo implements MarketRepository {
  _DisconnectedBookRepo(this._inner);

  final MarketRepository _inner;

  @override
  Future<Either<Failure, MarketAsset>> getAsset(
    Currency currency, {
    ChartPeriod period = ChartPeriod.oneDay,
  }) {
    return _inner.getAsset(currency, period: period);
  }

  @override
  Future<Either<Failure, PriceSeries>> getChart(
    Currency currency,
    ChartPeriod period,
  ) {
    return _inner.getChart(currency, period);
  }

  @override
  Future<Either<Failure, CandleSeries>> getCandles(
    Currency currency,
    CandleInterval interval,
  ) {
    return _inner.getCandles(currency, interval);
  }

  @override
  Stream<MarketTick> watchTicks(Currency currency) {
    return _inner.watchTicks(currency);
  }

  @override
  Future<Either<Failure, OrderBook>> getOrderBook(
    Currency currency, {
    int depth = orderBookDefaultDepth,
  }) async {
    final book = await _inner.getOrderBook(currency, depth: depth);
    return book.map(
      (value) => value.copyWith(freshness: QuoteFreshness.disconnected),
    );
  }

  @override
  Stream<OrderBook> watchOrderBook(
    Currency currency, {
    int depth = orderBookDefaultDepth,
  }) {
    return _inner.watchOrderBook(currency, depth: depth).map(
          (book) => book.copyWith(freshness: QuoteFreshness.disconnected),
        );
  }
}
