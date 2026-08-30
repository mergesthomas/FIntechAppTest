import 'package:equatable/equatable.dart';

import '../../../../core/settlement/settlement_status.dart';
import 'loan_product.dart';

final class CreditLineOptimization extends Equatable {
  const CreditLineOptimization({
    required this.product,
    required this.automaticCollateralTransfer,
    required this.fixedTermSavingsUnlock,
    required this.lowInterestBorrowing,
  });

  final LoanProductKind product;
  final bool automaticCollateralTransfer;
  final bool fixedTermSavingsUnlock;
  final bool lowInterestBorrowing;

  bool get isLegalCombination {
    if (automaticCollateralTransfer) {
      return true;
    }
    return !fixedTermSavingsUnlock && !lowInterestBorrowing;
  }

  @override
  List<Object?> get props => [
        product,
        automaticCollateralTransfer,
        fixedTermSavingsUnlock,
        lowInterestBorrowing,
      ];
}

final class LoanSettlement extends Equatable {
  const LoanSettlement({
    required this.requestId,
    required this.status,
  });

  final String requestId;
  final SettlementStatus status;

  @override
  List<Object?> get props => [requestId, status];
}
