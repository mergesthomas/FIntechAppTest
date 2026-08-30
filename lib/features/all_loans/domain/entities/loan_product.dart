import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

enum LoanProductKind { classic, card, zeroInterest, booster }

enum LoanListingGroup { active, available }

final class LoanProduct extends Equatable {
  const LoanProduct({
    required this.id,
    required this.kind,
    required this.group,
    required this.taglineKey,
    required this.termsKey,
    required this.available,
    required this.outstanding,
  });

  final String id;
  final LoanProductKind kind;
  final LoanListingGroup group;
  final String taglineKey;
  final String termsKey;
  final Money available;
  final Money outstanding;

  @override
  List<Object?> get props =>
      [id, kind, group, taglineKey, termsKey, available, outstanding];
}

final class AllLoansOverview extends Equatable {
  const AllLoansOverview({
    required this.maximumBorrowing,
    required this.totalOutstanding,
    required this.products,
  });

  final Money maximumBorrowing;
  final Money totalOutstanding;
  final List<LoanProduct> products;

  @override
  List<Object?> get props =>
      [maximumBorrowing, totalOutstanding, products];
}
