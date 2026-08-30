import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../entities/borrow.dart';

abstract class BorrowRepository {
  Future<Either<Failure, LoansOverview>> getOverview();
  Future<Either<Failure, List<LoanProduct>>> getProducts();
  Future<Either<Failure, CreditLineOverview>> getCreditLine(String productId);
  Future<Either<Failure, BorrowQuote>> getBorrowQuote({
    required String productId,
    required Money amount,
  });
  Future<Either<Failure, BorrowQuote>> getBorrowQuoteById(String quoteId);
  Future<Either<Failure, BorrowSubmit>> submitBorrow({
    required String requestId,
    required String quoteId,
  });
  Future<Either<Failure, BorrowSubmit>> submitRepay({
    required String requestId,
    required String loanId,
    required Money amount,
  });
  Future<Either<Failure, List<CollateralAsset>>> getCollateral();
  Future<Either<Failure, CreditLineOptimization>> getOptimization();
  Future<Either<Failure, SettlementStatus>> updateOptimization({
    required String requestId,
    required CreditLineOptimization flags,
  });
}
