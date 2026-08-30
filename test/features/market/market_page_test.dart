import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('watchlist opens market with chart and trade actions', (
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
    expect(find.byKey(const Key('market_chart')), findsOneWidget);
    expect(find.byKey(const Key('trade_buy')), findsOneWidget);
    expect(find.byKey(const Key('trade_exchange')), findsOneWidget);
    expect(find.byKey(const Key('trade_futures')), findsOneWidget);
  });
}
