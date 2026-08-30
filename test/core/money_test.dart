import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/money/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and formats USD without double', () {
    final money = Money.parse('35862.41', Currency.usd);
    expect(money.amount, Decimal.parse('35862.41'));
    expect(formatMoney(money), r'$35,862.41');
  });
}
