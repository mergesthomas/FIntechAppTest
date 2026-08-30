import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'currency.dart';

final class Money extends Equatable {
  const Money._(this.amount, this.currency);

  factory Money.parse(String input, Currency currency) {
    final normalized = input.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      throw FormatException('Money input is empty');
    }
    return Money._(Decimal.parse(normalized), currency);
  }

  factory Money.zero(Currency currency) => Money._(Decimal.zero, currency);

  factory Money.fromDecimal(Decimal amount, Currency currency) {
    return Money._(amount, currency);
  }

  final Decimal amount;
  final Currency currency;

  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('currency mismatch');
    }
    return Money._(amount + other.amount, currency);
  }

  Money operator -(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('currency mismatch');
    }
    return Money._(amount - other.amount, currency);
  }

  /// [rate] is units of [to] per one unit of this currency.
  Money convert(Decimal rate, Currency to) => Money._(amount * rate, to);

  bool get isNegative => amount < Decimal.zero;

  bool get isPositive => amount > Decimal.zero;

  @override
  List<Object?> get props => [amount, currency];

  @override
  String toString() => '$amount ${currency.code}';
}
