import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import 'loan_product.dart';

enum CollateralSort { creditLine, loanToValue }

final class CollateralAsset extends Equatable {
  const CollateralAsset({
    required this.currency,
    required this.displayName,
    required this.balance,
    required this.ltvRatio,
  });

  final Currency currency;
  final String displayName;
  final Money balance;

  /// LTV as a ratio (0.30 for 30%), never [double].
  final Decimal ltvRatio;

  @override
  List<Object?> get props => [currency, displayName, balance, ltvRatio];
}

final class CollateralFilter extends Equatable {
  const CollateralFilter({
    required this.creditLine,
    required this.sort,
  });

  final LoanProductKind creditLine;
  final CollateralSort sort;

  @override
  List<Object?> get props => [creditLine, sort];
}

final class AssetLtvEntry extends Equatable {
  const AssetLtvEntry({
    required this.currency,
    required this.ltvRatio,
  });

  final Currency currency;
  final Decimal ltvRatio;

  @override
  List<Object?> get props => [currency, ltvRatio];
}
