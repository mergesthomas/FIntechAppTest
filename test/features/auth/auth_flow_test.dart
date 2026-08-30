import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign up → SMS → PIN → skip Face ID → signed in', (tester) async {
    final store = InMemorySecureStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWith((ref) => store),
        ],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('phone_field')), '6912345678');
    await tester.tap(find.byKey(const Key('phone_continue')));
    await tester.pumpAndSettle();

    expect(find.text('Verify with SMS'), findsOneWidget);
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.text(digit).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Create PIN'), findsOneWidget);
    for (final digit in ['2', '5', '8', '0']) {
      await tester.tap(find.text(digit).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Confirm PIN'), findsOneWidget);
    for (final digit in ['2', '5', '8', '0']) {
      await tester.tap(find.text(digit).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skip_biometric')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('net_worth')), findsOneWidget);
  });
}
