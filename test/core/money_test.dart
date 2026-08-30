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

  test('adds subtracts and converts without double', () {
    final ten = Money.parse('10', Currency.nexo);
    expect((ten + Money.parse('2', Currency.nexo)).amount, Decimal.parse('12'));
    expect((ten - Money.parse('2', Currency.nexo)).amount, Decimal.parse('8'));
    expect(
      ten.convert(Decimal.parse('0.5'), Currency.eurx).amount,
      Decimal.parse('5'),
    );
  });
}
