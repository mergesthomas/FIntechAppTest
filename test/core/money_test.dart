import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('parses fiat without using double', () {
      final amount = Money.parse('14,694.96', Currency.xusd);

      expect(amount.amount, Decimal.parse('14694.96'));
      expect(amount.currency, Currency.xusd);
    });

    test('adds same-currency amounts', () {
      final classic = Money.parse('14625.44', Currency.xusd);
      final card = Money.parse('69.52', Currency.xusd);

      expect(classic + card, Money.parse('14694.96', Currency.xusd));
    });

    test('rejects empty input', () {
      expect(
        () => Money.parse('  ', Currency.eur),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects mixed-currency add', () {
      expect(
        () => Money.parse('10', Currency.eur) + Money.parse('10', Currency.usd),
        throwsArgumentError,
      );
    });
  });
}
