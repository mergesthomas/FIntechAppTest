import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('card hides cashback and internal frozen copy', (tester) async {
    final store = InMemorySecureStore();
    await store.write(AuthStoreKeys.sessionToken, 'token');
    await store.write(AuthStoreKeys.sessionPhone, '6912345678');
    await store.write(AuthStoreKeys.biometricEnabled, '0');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStoreProvider.overrideWith((ref) => store)],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();

    final nav = tester.getRect(find.byType(NavigationBar));
    await tester.tapAt(Offset(nav.left + nav.width * 5 / 8, nav.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Cashback earned'), findsNothing);
    expect(find.textContaining('compliance review'), findsNothing);
    expect(find.textContaining('first-class'), findsNothing);
    expect(find.text('Card frozen'), findsOneWidget);
    expect(find.byKey(const Key('restore_swap')), findsOneWidget);
    expect(find.text('Restore balance'), findsOneWidget);
  });
}
