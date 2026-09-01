import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fintech_app_test/features/swap/presentation/copy/swap_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/swap_flow.dart';

void main() {
  testWidgets('live quote swap confirms a paper fill', (tester) async {
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

    await tester.tap(find.byKey(const Key('nav_exchange')));
    await tester.pumpAndSettle();

    await enterSwapDigits(tester, '10');
    await tester.ensureVisible(find.byKey(const Key('swap_preview')));
    await tester.tap(find.byKey(const Key('swap_preview')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('swap_confirm')));
    await tester.pumpAndSettle();
    await enterStepUpPin(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('swap_result')), findsOneWidget);
    expect(find.text(SwapCopy.confirmed), findsOneWidget);
    expect(find.byKey(const Key('view_orders')), findsOneWidget);
    expect(find.byKey(const Key('swap_done')), findsOneWidget);
    expect(find.text(SwapCopy.viewOrders), findsOneWidget);
  });

  testWidgets('limit and trigger fields appear from the order type sheet', (
    tester,
  ) async {
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
    await tester.tap(find.byKey(const Key('nav_exchange')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('swap_order_type')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap_type_limit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap_limit_price')), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('swap_preview'))).onPressed,
      isNull,
    );
    expect(find.text('Retry'), findsNothing);
    expect(find.textContaining('ValidationFailure'), findsNothing);

    await tester.tap(find.byKey(const Key('swap_order_type')));
    await tester.pumpAndSettle();
    expect(find.text(SwapCopy.orderType), findsWidgets);
    expect(find.text(SwapCopy.instantOrder), findsWidgets);
    expect(find.text(SwapCopy.limitOrder), findsWidgets);
    await tester.tap(find.byKey(const Key('swap_type_trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap_take_profit')), findsOneWidget);
    expect(find.byKey(const Key('swap_stop_loss')), findsOneWidget);
  });

  testWidgets('live limit order is placed not filled', (tester) async {
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
    await tester.tap(find.byKey(const Key('nav_exchange')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('swap_order_type')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap_type_limit')));
    await tester.pumpAndSettle();

    await enterSwapDigits(tester, '10');
    await tester.tap(find.byKey(const Key('swap_limit_price')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('swap_key_dot')));
    await tester.pump();
    await enterSwapDigits(tester, '0001');

    await tester.ensureVisible(find.byKey(const Key('swap_preview')));
    await tester.tap(find.byKey(const Key('swap_preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap_confirm')));
    await tester.pumpAndSettle();
    await enterStepUpPin(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('swap_result')), findsOneWidget);
    expect(find.text(SwapCopy.placed), findsOneWidget);
    expect(find.byKey(const Key('view_orders')), findsOneWidget);
    expect(find.byKey(const Key('swap_done')), findsOneWidget);
  });
}
