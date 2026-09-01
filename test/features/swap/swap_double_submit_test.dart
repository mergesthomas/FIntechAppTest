import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/ledger/paper_settler.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/swap_flow.dart';

/// Seeded fixture buys share the store, so count only swap submits.
List<PaperOrder> swapOrders(PaperOrderStore store) {
  return store.all
      .where((order) => order.requestId.startsWith('swap-'))
      .toList();
}

Future<PaperOrderStore> pumpLiveSwap(
  WidgetTester tester, {
  Duration settleDelay = Duration.zero,
}) async {
  final secure = InMemorySecureStore();
  await secure.write(AuthStoreKeys.sessionToken, 'token');
  await secure.write(AuthStoreKeys.sessionPhone, '6912345678');
  await secure.write(AuthStoreKeys.biometricEnabled, '0');
  final orders = PaperOrderStore();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStoreProvider.overrideWith((ref) => secure),
        paperOrderStoreProvider.overrideWith((ref) => orders),
        if (settleDelay > Duration.zero)
          paperSettlerProvider.overrideWith(
            (ref) => DelayedPaperSettler(delay: settleDelay),
          ),
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
  return orders;
}

Future<void> previewTenUsdc(WidgetTester tester) async {
  await enterSwapDigits(tester, '10');
  await tester.ensureVisible(find.byKey(const Key('swap_preview')));
  await tester.tap(find.byKey(const Key('swap_preview')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirm is not tappable while the submit is in flight', (
    tester,
  ) async {
    final orders = await pumpLiveSwap(
      tester,
      settleDelay: const Duration(milliseconds: 400),
    );
    await previewTenUsdc(tester);

    await tester.tap(find.byKey(const Key('swap_confirm')));
    await tester.pumpAndSettle();
    await enterStepUpPin(tester);
    await tester.pump();

    // Mid-flight: the button exists, has no handler, and shows a spinner.
    final button = find.byKey(const Key('swap_confirm'));
    expect(button, findsOneWidget);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    expect(find.byKey(const Key('swap_confirm_spinner')), findsOneWidget);

    // A tap mid-flight must not queue a second submit.
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap_result')), findsOneWidget);
    expect(swapOrders(orders), hasLength(1));
  });

  testWidgets('a genuine second order is not swallowed by idempotency', (
    tester,
  ) async {
    final orders = await pumpLiveSwap(tester);

    await previewTenUsdc(tester);
    await tester.tap(find.byKey(const Key('swap_confirm')));
    await tester.pumpAndSettle();
    await enterStepUpPin(tester);
    await tester.pumpAndSettle();
    expect(swapOrders(orders), hasLength(1));
    final first = swapOrders(orders).single.requestId;

    // Done returns to the ticket, which drops the request id. The identical
    // amount is a new intent, so it must place a second distinct order.
    await tester.tap(find.byKey(const Key('swap_done')));
    await tester.pumpAndSettle();
    await previewTenUsdc(tester);
    await tester.tap(find.byKey(const Key('swap_confirm')));
    await tester.pumpAndSettle();
    await enterStepUpPin(tester);
    await tester.pumpAndSettle();

    final placed = swapOrders(orders);
    expect(placed, hasLength(2));
    expect(placed.map((order) => order.requestId).toSet(), hasLength(2));
    expect(placed.map((order) => order.requestId), contains(first));
  });
}
