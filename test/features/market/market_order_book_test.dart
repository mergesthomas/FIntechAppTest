import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/theme/app_theme.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/domain/entities/order_book.dart';
import 'package:fintech_app_test/features/market/presentation/widgets/market_order_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('phone-width BTC book does not overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        overflows.add(text);
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    final book = const MarketLocalDataSource().bookFor(Currency.btc)!;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MarketOrderBook(book: book),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('market_order_book')), findsOneWidget);
    expect(find.byKey(const Key('market_order_book_spread')), findsOneWidget);
    expect(overflows, isEmpty);
  });

  testWidgets('wide live-style prices stay inside each half', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        overflows.add(text);
      }
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    final at = DateTime.utc(2026, 1, 1);
    final book = OrderBook.normalized(
      currency: Currency.btc,
      quote: Currency.usdt,
      bids: [
        OrderBookLevel(
          side: OrderBookSide.bid,
          price: Money.parse('78854.11', Currency.usdt),
          size: Money.parse('0.03169', Currency.btc),
        ),
      ],
      asks: [
        OrderBookLevel(
          side: OrderBookSide.ask,
          price: Money.parse('78854.12', Currency.usdt),
          size: Money.parse('6.06894', Currency.btc),
        ),
      ],
      freshness: QuoteFreshness.stale,
      updatedAt: at,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MarketOrderBook(book: book),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('78,854.11'), findsOneWidget);
    expect(find.text('78,854.12'), findsOneWidget);
    expect(find.text('0.03169'), findsOneWidget);
    expect(find.text('6.06894'), findsOneWidget);
    expect(overflows, isEmpty);
  });
}
