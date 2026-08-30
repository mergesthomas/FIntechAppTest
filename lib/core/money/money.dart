import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'currency.dart';

/// Ledger amount. Never use [double] for balances, prices, fees, or rates.
final class Money extends Equatable {
  const Money._(this.amount, this.currency);

  factory Money.parse(String input, Currency currency) {
    final normalized = input.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      throw FormatException('Money input is empty');
    }
    final parsed = Decimal.parse(normalized);
    return Money._(parsed, currency);
  }

  factory Money.fromDecimal(Decimal amount, Currency currency) {
    return Money._(amount, currency);
  }

  factory Money.zero(Currency currency) {
    return Money._(Decimal.zero, currency);
  }

  final Decimal amount;
  final Currency currency;

  bool get isZero => amount == Decimal.zero;

  bool get isNegative => amount < Decimal.zero;

  bool get isPositive => amount > Decimal.zero;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money._(amount + other.amount, currency);
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Currency mismatch: ${currency.code} vs ${other.currency.code}',
      );
    }
  }

  @override
  List<Object?> get props => [amount, currency];

  @override
  String toString() => '${amount.toString()} ${currency.code}';
}
