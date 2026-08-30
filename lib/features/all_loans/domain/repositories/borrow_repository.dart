import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/borrow_quote.dart';
import '../entities/credit_line_optimization.dart';
import '../entities/loan_product.dart';

abstract class BorrowRepository {
  Future<Either<Failure, BorrowQuote>> getQuote({
    required LoanProductKind product,
    required Money amount,
  });

  Future<Either<Failure, BorrowQuote>> getQuoteById(String quoteId);

  Future<Either<Failure, LoanSettlement>> submitBorrow({
    required String requestId,
    required String quoteId,
    required LoanProductKind product,
    required Money amount,
  });

  Future<Either<Failure, LoanSettlement>> submitRepay({
    required String requestId,
    required String loanId,
    required Money amount,
  });
}
