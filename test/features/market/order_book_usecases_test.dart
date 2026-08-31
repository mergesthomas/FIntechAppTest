import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/repositories/market_repository_impl.dart';
import 'package:fintech_app_test/features/market/domain/entities/order_book.dart';
import 'package:fintech_app_test/features/market/domain/repositories/market_repository.dart';
import 'package:fintech_app_test/features/market/domain/usecases/market_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/paper_harness.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockMarketRepository extends Mock implements MarketRepository {}

void main() {
  late MockAuthRepository auth;
  late MarketRepositoryImpl fixtureRepo;

  const session = Session(
    token: 't',
    phone: '6912345678',
    biometricEnabled: false,
  );

  setUp(() {
    auth = MockAuthRepository();
    fixtureRepo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: PaperHarness().feed,
    );
  });

  void signedOut() {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
  }

  void signedIn() {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(session),
    );
  }

  OrderBook sampleBook({
    QuoteFreshness freshness = QuoteFreshness.stale,
  }) {
    return OrderBook.normalized(
      currency: Currency.btc,
      quote: Currency.usdt,
      bids: [
        OrderBookLevel(
          side: OrderBookSide.bid,
          price: Money.parse('78898.13', Currency.usdt),
          size: Money.parse('0.2', Currency.btc),
        ),
      ],
      asks: [
        OrderBookLevel(
          side: OrderBookSide.ask,
          price: Money.parse('78900.13', Currency.usdt),
          size: Money.parse('0.1', Currency.btc),
        ),
      ],
      freshness: freshness,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('GetOrderBook refuses without a session', () async {
    signedOut();
    final getBook = GetOrderBook(RequireSession(auth), fixtureRepo);
    final result = await getBook((
      currency: Currency.btc,
      depth: orderBookDefaultDepth,
    ));
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('GetOrderBook refuses an invalid depth', () async {
    signedIn();
    final getBook = GetOrderBook(RequireSession(auth), fixtureRepo);
    final zero = await getBook((currency: Currency.btc, depth: 0));
    final wide = await getBook((currency: Currency.btc, depth: 21));
    expect(zero.getLeft().toNullable(), isA<ValidationFailure>());
    expect(wide.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('GetOrderBook returns a stale fixture book when session exists', () async {
    signedIn();
    final getBook = GetOrderBook(RequireSession(auth), fixtureRepo);
    final result = await getBook((
      currency: Currency.btc,
      depth: orderBookDefaultDepth,
    ));
    final book = result.getRight().toNullable();
    expect(book?.currency, Currency.btc);
    expect(book?.freshness, QuoteFreshness.stale);
    expect(book?.bids, hasLength(orderBookDefaultDepth));
  });

  test('WatchOrderBook refuses without a session', () async {
    signedOut();
    final watch = WatchOrderBook(RequireSession(auth), fixtureRepo);
    final first = await watch((
      currency: Currency.btc,
      depth: orderBookDefaultDepth,
    )).first;
    expect(first.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('WatchOrderBook emits the fixture book when session exists', () async {
    signedIn();
    final watch = WatchOrderBook(RequireSession(auth), fixtureRepo);
    final first = await watch((
      currency: Currency.btc,
      depth: 5,
    )).first;
    expect(first.getRight().toNullable()?.asks, hasLength(5));
    expect(first.getRight().toNullable()?.freshness, QuoteFreshness.stale);
  });

  test('SelectOrderBookLevel refuses without a session', () async {
    signedOut();
    final select = SelectOrderBookLevel(RequireSession(auth), fixtureRepo);
    final book = (await fixtureRepo.getOrderBook(Currency.btc)).getRight();
    final result = await select((
      currency: Currency.btc,
      side: OrderBookSide.bid,
      price: book.toNullable()!.bids.first.price,
    ));
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('SelectOrderBookLevel refuses a disconnected book', () async {
    signedIn();
    final market = MockMarketRepository();
    when(
      () => market.getOrderBook(
        Currency.btc,
        depth: any(named: 'depth'),
      ),
    ).thenAnswer(
      (_) async => Either.right(
        sampleBook(freshness: QuoteFreshness.disconnected),
      ),
    );
    final select = SelectOrderBookLevel(RequireSession(auth), market);
    final result = await select((
      currency: Currency.btc,
      side: OrderBookSide.bid,
      price: Money.parse('78898.13', Currency.usdt),
    ));
    expect(result.getLeft().toNullable(), isA<StaleQuoteFailure>());
  });

  test('SelectOrderBookLevel returns a stale draft without submitting', () async {
    signedIn();
    final select = SelectOrderBookLevel(RequireSession(auth), fixtureRepo);
    final book = (await fixtureRepo.getOrderBook(Currency.btc)).getRight();
    final level = book.toNullable()!.bids.first;
    final result = await select((
      currency: Currency.btc,
      side: OrderBookSide.bid,
      price: level.price,
    ));
    final draft = result.getRight().toNullable();
    expect(draft?.limitPrice, level.price);
    expect(draft?.size, level.size);
    expect(draft?.freshness, QuoteFreshness.stale);
    expect(draft?.side, OrderBookSide.bid);
  });

  test('SelectOrderBookLevel keeps live freshness on the draft', () async {
    signedIn();
    final market = MockMarketRepository();
    final live = sampleBook(freshness: QuoteFreshness.live);
    when(
      () => market.getOrderBook(
        Currency.btc,
        depth: any(named: 'depth'),
      ),
    ).thenAnswer((_) async => Either.right(live));
    final select = SelectOrderBookLevel(RequireSession(auth), market);
    final result = await select((
      currency: Currency.btc,
      side: OrderBookSide.ask,
      price: live.asks.first.price,
    ));
    expect(result.getRight().toNullable()?.freshness, QuoteFreshness.live);
    expect(result.getRight().toNullable()?.limitPrice, live.asks.first.price);
  });

  test('SelectOrderBookLevel refuses a price that is not on the book', () async {
    signedIn();
    final select = SelectOrderBookLevel(RequireSession(auth), fixtureRepo);
    final result = await select((
      currency: Currency.btc,
      side: OrderBookSide.bid,
      price: Money.parse('1', Currency.usdt),
    ));
    expect(
      result.getLeft().toNullable(),
      const ValidationFailure('book_level_unknown'),
    );
  });
}
