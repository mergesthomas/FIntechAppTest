import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../money/currency.dart';

/// Confirmed wallet delta used to rebuild portfolio value over time.
final class LedgerLot extends Equatable {
  const LedgerLot({
    required this.currency,
    required this.quantity,
    required this.at,
  });

  final Currency currency;
  final Decimal quantity;
  final DateTime at;

  @override
  List<Object?> get props => [currency, quantity, at];
}
