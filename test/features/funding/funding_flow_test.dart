import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('buy preview confirm is rejected because the quote is stale', (
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

    await tester.tap(find.byKey(const Key('add_funds')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('funding_buyCrypto')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('buy_asset_BTC')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('buy_amount')), '100');
    await tester.tap(find.byKey(const Key('buy_preview')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('buy_confirm')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buy_result')), findsOneWidget);
    expect(find.textContaining('stale'), findsWidgets);
  });
}
