import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/swap_flow.dart';

void main() {
  testWidgets('swap confirm is rejected because the quote is stale', (
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
    expect(find.textContaining('stale'), findsWidgets);
  });
}
