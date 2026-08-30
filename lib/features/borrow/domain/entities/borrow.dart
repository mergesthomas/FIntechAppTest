import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';

enum LoanHealth { good, warning, call }

final class LoansOverview extends Equatable {
  const LoansOverview({
    required this.available,
    required this.outstanding,
  });

  final Money available;
  final Money outstanding;

  @override
  List<Object?> get props => [available, outstanding];
}

final class LoanProduct extends Equatable {
  const LoanProduct({
    required this.id,
    required this.label,
    required this.status,
    required this.outstanding,
  });

  final String id;
  final String label;
  final String status;
  final Money outstanding;

  @override
  List<Object?> get props => [id, label, status, outstanding];
}

final class CreditLineOverview extends Equatable {
  const CreditLineOverview({
    required this.productId,
    required this.available,
    required this.outstanding,
    required this.health,
  });

  final String productId;
  final Money available;
  final Money outstanding;
  final LoanHealth health;

  @override
  List<Object?> get props => [productId, available, outstanding, health];
}

final class BorrowQuote extends Equatable {
  const BorrowQuote({
    required this.quoteId,
    required this.productId,
    required this.amount,
    required this.ltvTeaser,
    required this.freshness,
  });

  final String quoteId;
  final String productId;
  final Money amount;
  final String ltvTeaser;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [quoteId, productId, amount, ltvTeaser, freshness];
}

final class CollateralAsset extends Equatable {
  const CollateralAsset({
    required this.currency,
    required this.ltvTeaser,
  });

  final Currency currency;
  final String ltvTeaser;

  @override
  List<Object?> get props => [currency, ltvTeaser];
}

final class CreditLineOptimization extends Equatable {
  const CreditLineOptimization({
    required this.automaticCollateralTransfer,
    required this.fixedTermUnlock,
    required this.lowInterestBorrowing,
  });

  final bool automaticCollateralTransfer;
  final bool fixedTermUnlock;
  final bool lowInterestBorrowing;

  CreditLineOptimization copyWith({
    bool? automaticCollateralTransfer,
    bool? fixedTermUnlock,
    bool? lowInterestBorrowing,
  }) {
    return CreditLineOptimization(
      automaticCollateralTransfer:
          automaticCollateralTransfer ?? this.automaticCollateralTransfer,
      fixedTermUnlock: fixedTermUnlock ?? this.fixedTermUnlock,
      lowInterestBorrowing: lowInterestBorrowing ?? this.lowInterestBorrowing,
    );
  }

  @override
  List<Object?> get props => [
        automaticCollateralTransfer,
        fixedTermUnlock,
        lowInterestBorrowing,
      ];
}

final class BorrowSubmit extends Equatable {
  const BorrowSubmit({
    required this.requestId,
    required this.settlement,
  });

  final String requestId;
  final SettlementStatus settlement;

  @override
  List<Object?> get props => [requestId, settlement];
}
