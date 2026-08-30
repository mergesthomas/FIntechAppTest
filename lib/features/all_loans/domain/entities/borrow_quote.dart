import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/money.dart';
import 'loan_product.dart';

final class BorrowQuote extends Equatable {
  const BorrowQuote({
    required this.quoteId,
    required this.product,
    required this.amount,
    required this.freshness,
  });

  final String quoteId;
  final LoanProductKind product;
  final Money amount;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [quoteId, product, amount, freshness];
}
