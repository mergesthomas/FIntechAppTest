import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/widgets/freshness_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('live chip prints nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FreshnessChip(freshness: QuoteFreshness.live),
        ),
      ),
    );

    expect(find.text('live'), findsNothing);
  });

  testWidgets('stale chip stays visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FreshnessChip(freshness: QuoteFreshness.stale),
        ),
      ),
    );

    expect(find.text('stale'), findsOneWidget);
  });
}
