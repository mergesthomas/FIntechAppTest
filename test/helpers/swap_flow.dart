import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> enterSwapDigits(WidgetTester tester, String digits) async {
  for (final ch in digits.split('')) {
    final key = Key('swap_key_$ch');
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
  }
}

Future<void> enterStepUpPin(WidgetTester tester) async {
  final dialog = find.byType(AlertDialog);
  for (final digit in ['1', '2', '3', '4']) {
    await tester.tap(find.descendant(of: dialog, matching: find.text(digit)));
    await tester.pump();
  }
}
