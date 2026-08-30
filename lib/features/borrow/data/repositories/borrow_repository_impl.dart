import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/borrow.dart';
import '../../domain/repositories/borrow_repository.dart';
import '../datasources/borrow_local_datasource.dart';

final class BorrowRepositoryImpl implements BorrowRepository {
  BorrowRepositoryImpl(this._local);

  final BorrowLocalDataSource _local;

  @override
  Future<Either<Failure, LoansOverview>> getOverview() async {
    return Either.right(_local.overview());
  }

  @override
  Future<Either<Failure, List<LoanProduct>>> getProducts() async {
    return Either.right(_local.products());
  }

  @override
  Future<Either<Failure, CreditLineOverview>> getCreditLine(
    String productId,
  ) async {
    return Either.right(_local.creditLine(productId));
  }

  @override
  Future<Either<Failure, BorrowQuote>> getBorrowQuote({
    required String productId,
    required Money amount,
  }) async {
    return Either.right(_local.quote(productId: productId, amount: amount));
  }

  @override
  Future<Either<Failure, BorrowQuote>> getBorrowQuoteById(String quoteId) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    return Either.right(quote);
  }

  @override
  Future<Either<Failure, BorrowSubmit>> submitBorrow({
    required String requestId,
    required String quoteId,
  }) async {
    return Either.right(
      _local.borrow(requestId: requestId, quoteId: quoteId),
    );
  }

  @override
  Future<Either<Failure, BorrowSubmit>> submitRepay({
    required String requestId,
    required String loanId,
    required Money amount,
  }) async {
    return Either.right(
      _local.repay(requestId: requestId, loanId: loanId, amount: amount),
    );
  }

  @override
  Future<Either<Failure, List<CollateralAsset>>> getCollateral() async {
    return Either.right(_local.collateral());
  }

  @override
  Future<Either<Failure, CreditLineOptimization>> getOptimization() async {
    return Either.right(_local.optimization);
  }

  @override
  Future<Either<Failure, SettlementStatus>> updateOptimization({
    required String requestId,
    required CreditLineOptimization flags,
  }) async {
    return Either.right(
      _local.updateOptimization(requestId: requestId, flags: flags),
    );
  }
}
