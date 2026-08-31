import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/widgets/asset_list_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sparklines share the same x origin across price widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: Column(
              children: [
                AssetListRow(
                  symbol: 'BTC',
                  subtitle: 'Bitcoin · stale',
                  priceLabel: r'$78,899.13',
                  changeLabel: '+1.54%',
                  change: Decimal.parse('0.0154'),
                  leadingTrail: const SizedBox(
                    key: Key('spark_btc'),
                    width: 56,
                    height: 24,
                  ),
                ),
                AssetListRow(
                  symbol: 'PEPE',
                  subtitle: 'Pepe · stale',
                  priceLabel: r'$0.00001',
                  changeLabel: '+3.20%',
                  change: Decimal.parse('0.0320'),
                  leadingTrail: const SizedBox(
                    key: Key('spark_pepe'),
                    width: 56,
                    height: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final btc = tester.getTopLeft(find.byKey(const Key('spark_btc')));
    final pepe = tester.getTopLeft(find.byKey(const Key('spark_pepe')));
    expect(btc.dx, closeTo(pepe.dx, 0.5));
  });
}
