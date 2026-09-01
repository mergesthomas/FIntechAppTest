import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/money/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromCode keeps listed scale and accepts catalog tickers', () {
    expect(Currency.fromCode('BTC'), Currency.btc);
    expect(Currency.fromCode('ADA')?.code, 'ADA');
    expect(Currency.fromCode('ADA')?.scale, 8);
    expect(Currency.fromCode(''), isNull);
  });

  test('parses and formats USD without double', () {
    final money = Money.parse('35862.41', Currency.usd);
    expect(money.amount, Decimal.parse('35862.41'));
    expect(formatMoney(money), r'$35,862.41');
  });

  test('formats sub-cent USD quotes instead of \$0.00', () {
    expect(formatMoney(Money.parse('0.00000282', Currency.usd)), r'$0.0000028');
    expect(formatMoney(Money.parse('0.00000353', Currency.usd)), r'$0.0000035');
    expect(formatMoney(Money.parse('0.08', Currency.usd)), r'$0.08');
    expect(formatMoney(Money.parse('0.0824', Currency.usd)), r'$0.0824');
  });

  test('caps everyday crypto quantities and trims zeros', () {
    expect(
      formatQuantity(Money.parse('10000.000000', Currency.usdc)),
      '10,000 USDC',
    );
    expect(
      formatQuantity(Money.parse('10000.00000000', Currency.doge)),
      '10,000 DOGE',
    );
    expect(
      formatMoney(Money.parse('12122.77299721', Currency.doge), withCode: false),
      '12,122.773',
    );
    expect(
      formatRate(Money.parse('12.11971404', Currency.doge)),
      '12.119714 DOGE',
    );
  });

  test('keeps PEPE and BONK dust precision', () {
    expect(
      formatQuantity(Money.parse('80000000.00000000', Currency.pepe)),
      '80,000,000 PEPE',
    );
    expect(formatMoney(Money.parse('0.00000282', Currency.usd)), r'$0.0000028');
  });

  test('formats percents to two fraction digits', () {
    expect(formatPercent(Decimal.parse('-0.0150755')), '-1.51%');
    expect(formatPercent(Decimal.parse('0.012')), '+1.20%');
    expect(formatPercent(Decimal.zero), '0.00%');
  });

  test('formats OHLC decimals with a stable scale', () {
    expect(formatMarketDecimal(Decimal.parse('157.96999')), '157.97');
    expect(formatMarketDecimal(Decimal.parse('78052.64')), '78,052.64');
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
