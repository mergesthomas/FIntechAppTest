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

  test('formats sub-cent USD quotes instead of \$0.00', () {
    expect(formatMoney(Money.parse('0.00000282', Currency.usd)), r'$0.0000028');
    expect(formatMoney(Money.parse('0.00000353', Currency.usd)), r'$0.0000035');
    expect(formatMoney(Money.parse('0.08', Currency.usd)), r'$0.08');
  });

  test('adds subtracts and converts without double', () {
    final ten = Money.parse('10', Currency.usdc);
    expect((ten + Money.parse('2', Currency.usdc)).amount, Decimal.parse('12'));
    expect((ten - Money.parse('2', Currency.usdc)).amount, Decimal.parse('8'));
    expect(
      ten.convert(Decimal.parse('0.5'), Currency.eurx).amount,
      Decimal.parse('5'),
    );
  });

  test('formats holding quantities with grouping and the asset code', () {
    expect(
      formatQuantity(Money.parse('80000000', Currency.pepe)),
      '80,000,000 PEPE',
    );
    expect(formatQuantity(Money.parse('0.15', Currency.btc)), '0.15 BTC');
    expect(
      formatQuantity(Money.parse('10000.00', Currency.usdc)),
      '10,000 USDC',
    );
    expect(
      formatQuantity(Money.parse('78854.11', Currency.usdt), withCode: false),
      '78,854.11',
    );
  });

  test('NEXO is not a listed currency', () {
    expect(Currency.tryParse('NEXO'), isNull);
  });
}
