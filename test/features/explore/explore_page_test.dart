import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explore shows movers without For you or Products', (
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
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Top movers'), findsOneWidget);
    expect(find.text('For you'), findsNothing);
    expect(find.text('Products'), findsNothing);
    expect(find.text('Recurring Buy'), findsNothing);
  });
}
