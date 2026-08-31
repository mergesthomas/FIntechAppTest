import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fintech_app_test/features/inbox/presentation/copy/inbox_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inbox lists seeded trades with that-day buy prices', (tester) async {
    final store = InMemorySecureStore();
    await store.write(AuthStoreKeys.sessionToken, 'token');
    await store.write(AuthStoreKeys.sessionPhone, '6912345678');
    await store.write(AuthStoreKeys.biometricEnabled, '0');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWith((ref) => store),
          marketFeedProvider.overrideWith(
            (ref) => InMemoryMarketFeed(connection: QuoteFreshness.stale),
          ),
        ],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inbox')));
    await tester.pumpAndSettle();

    expect(find.text(InboxCopy.title), findsWidgets);
    expect(find.text('Interest Earned'), findsNothing);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Bought BTC'), findsOneWidget);
    expect(find.text('Bought USDC'), findsOneWidget);
    expect(find.text('Bought DOGE'), findsOneWidget);
    expect(find.text('Bought PEPE'), findsOneWidget);
    expect(find.text('0.15 BTC'), findsOneWidget);
    expect(find.text('80,000,000 PEPE'), findsOneWidget);
    expect(find.textContaining(r'$'), findsWidgets);
    expect(find.byKey(const Key('inbox_item_interest-usd')), findsNothing);
    expect(find.byKey(const Key('inbox_item_ord-seed-buy-btc')), findsOneWidget);
  });
}
