import 'package:fintech_app_test/features/auth/presentation/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PIN 0 sits under 8 on the keypad grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinKeypad(onDigit: (_) {}, onBackspace: () {}),
        ),
      ),
    );

    final eight = tester.getCenter(find.text('8'));
    final zero = tester.getCenter(find.text('0'));
    expect((eight.dx - zero.dx).abs(), lessThan(1));
  });
}
