import 'package:candlesticks/candlesticks.dart';
import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/candle_series.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/core/theme/app_colors.dart';
import 'package:fintech_app_test/core/widgets/price_chart.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/repositories/market_repository_impl.dart';
import 'package:fintech_app_test/features/market/domain/entities/market_asset.dart';
import 'package:fintech_app_test/features/market/domain/entities/market_tick.dart';
import 'package:fintech_app_test/features/market/domain/entities/order_book.dart';
import 'package:fintech_app_test/features/market/domain/repositories/market_repository.dart';
import 'package:fintech_app_test/features/swap/presentation/copy/swap_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/paper_harness.dart';

void main() {
  testWidgets(
    'watchlist opens market with candlestick chart and trade actions',
    (tester) async {
      final store = InMemorySecureStore();
      await store.write(AuthStoreKeys.sessionToken, 'token');
      await store.write(AuthStoreKeys.sessionPhone, '6912345678');
      await store.write(AuthStoreKeys.biometricEnabled, '0');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [secureStoreProvider.overrideWith((ref) => store)],
          child: const FintechApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PriceChart), findsWidgets);
      expect(find.byType(Candlesticks), findsNothing);

      await tester.drag(
        find.byKey(const Key('dashboard_scroll')),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('watchlist_BTC')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('market_price')), findsOneWidget);
      expect(find.byKey(const Key('market_candlestick_chart')), findsOneWidget);
      expect(find.byType(Candlesticks), findsOneWidget);
      expect(
        tester
            .widget<Candlesticks>(find.byType(Candlesticks))
            .style
            ?.chartBackgroundColor,
        AppColors.background,
      );
      expect(find.byType(PriceChart), findsNothing);
      expect(find.byKey(const Key('candle_interval_m15')), findsOneWidget);
      expect(find.byKey(const Key('market_volume_toggle')), findsOneWidget);
      expect(find.byKey(const Key('market_zoom_reset')), findsOneWidget);
      expect(find.byKey(const Key('market_ohlc_stats')), findsOneWidget);
      expect(find.byKey(const Key('trade_buy')), findsNothing);
      expect(find.byKey(const Key('trade_exchange')), findsOneWidget);
      expect(find.byKey(const Key('trade_futures')), findsNothing);
      await tester.drag(
        find.byKey(const Key('market_scroll')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('market_order_book')), findsOneWidget);
      expect(find.byKey(const Key('market_order_book_spread')), findsOneWidget);
    },
  );

  testWidgets('timeframe chip reloads candles on the market page', (
    tester,
  ) async {
    final store = InMemorySecureStore();
    await store.write(AuthStoreKeys.sessionToken, 'token');
    await store.write(AuthStoreKeys.sessionPhone, '6912345678');
    await store.write(AuthStoreKeys.biometricEnabled, '0');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWith((ref) => store)],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_BTC')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('candle_interval_h1')));
    await tester.pumpAndSettle();

    expect(find.byType(Candlesticks), findsOneWidget);
    expect(find.byKey(const Key('market_candlestick_chart')), findsOneWidget);
  });

  testWidgets('market price does not print live', (tester) async {
    final store = InMemorySecureStore();
    await store.write(AuthStoreKeys.sessionToken, 'token');
    await store.write(AuthStoreKeys.sessionPhone, '6912345678');
    await store.write(AuthStoreKeys.biometricEnabled, '0');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWith((ref) => store),
          marketFeedProvider.overrideWith(
            (ref) => InMemoryMarketFeed(connection: QuoteFreshness.live),
          ),
        ],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_BTC')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('market_price')), findsOneWidget);
    expect(find.text('live'), findsNothing);
  });

  testWidgets('tapping a bid opens Swap Limit and does not submit', (
    tester,
  ) async {
    final store = InMemorySecureStore();
    await store.write(AuthStoreKeys.sessionToken, 'token');
    await store.write(AuthStoreKeys.sessionPhone, '6912345678');
    await store.write(AuthStoreKeys.biometricEnabled, '0');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWith((ref) => store)],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_BTC')));
    await tester.pumpAndSettle();

    final book = const MarketLocalDataSource().bookFor(Currency.btc)!;
    final bidKey = Key('order_book_bid_${book.bids.first.price.amount}');
    await tester.drag(
      find.byKey(const Key('market_scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(bidKey));
    await tester.pumpAndSettle();

    expect(find.text(SwapCopy.limitOrder), findsOneWidget);
    expect(find.byKey(const Key('swap_limit_price')), findsOneWidget);
    expect(
      find.textContaining(book.bids.first.price.amount.toString()),
      findsWidgets,
    );
    expect(find.byKey(const Key('swap_result')), findsNothing);
    expect(find.byKey(const Key('swap_confirm')), findsNothing);
  });

  testWidgets('disconnected book levels do not open Swap', (tester) async {
    final store = InMemorySecureStore();
    await store.write(AuthStoreKeys.sessionToken, 'token');
    await store.write(AuthStoreKeys.sessionPhone, '6912345678');
    await store.write(AuthStoreKeys.biometricEnabled, '0');
    final paper = PaperHarness();
    final repo = _DisconnectedBookRepo(
      MarketRepositoryImpl(const MarketLocalDataSource(), feed: paper.feed),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWith((ref) => store),
          marketFeedProvider.overrideWith((ref) => paper.feed),
          marketRepositoryProvider.overrideWith((ref) => repo),
        ],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_BTC')));
    await tester.pumpAndSettle();

    final book = const MarketLocalDataSource().bookFor(Currency.btc)!;
    final bidKey = Key('order_book_bid_${book.bids.first.price.amount}');
    await tester.drag(
      find.byKey(const Key('market_scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(bidKey));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('swap_limit_price')), findsNothing);
    expect(find.byKey(const Key('market_order_book')), findsOneWidget);
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
    return _inner
        .watchOrderBook(currency, depth: depth)
        .map((book) => book.copyWith(freshness: QuoteFreshness.disconnected));
  }
}
