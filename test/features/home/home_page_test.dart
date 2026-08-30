import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('restored session shows stale portfolio', (tester) async {
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

    expect(find.byKey(const Key('net_worth')), findsOneWidget);
    expect(find.textContaining('stale'), findsWidgets);
    expect(find.byKey(const Key('trade_buy')), findsOneWidget);
    expect(find.byKey(const Key('add_funds')), findsOneWidget);
  });
}
