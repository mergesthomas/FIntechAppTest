import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/auth/product_area.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/borrow_quote.dart';
import '../../entities/credit_line_optimization.dart';
import '../../entities/loan_product.dart';
import '../../repositories/borrow_repository.dart';

final class GetBorrowQuoteParams extends Equatable {
  const GetBorrowQuoteParams({
    required this.product,
    required this.amount,
  });

  final LoanProductKind product;
  final Money amount;

  @override
  List<Object?> get props => [product, amount];
}

final class GetBorrowQuote implements UseCase<BorrowQuote, GetBorrowQuoteParams> {
  GetBorrowQuote(this._guards, this._borrow);

  final AccessGuards _guards;
  final BorrowRepository _borrow;

  @override
  Future<Either<Failure, BorrowQuote>> call(GetBorrowQuoteParams params) async {
    final gate = await _guards.requireApproved(ProductArea.borrow);
    if (gate.isLeft()) {
      return gate.hideRight();
    }
    if (!params.amount.isPositive) {
      return Either.left(const ValidationFailure('amount_must_be_positive'));
    }
    return _borrow.getQuote(product: params.product, amount: params.amount);
  }
}

final class SubmitBorrowParams extends Equatable {
  const SubmitBorrowParams({
    required this.requestId,
    required this.quoteId,
    required this.product,
    required this.amount,
    required this.stepUpVerified,
  });

  final String requestId;
  final String quoteId;
  final LoanProductKind product;
  final Money amount;
  final bool stepUpVerified;

  @override
  List<Object?> get props =>
      [requestId, quoteId, product, amount, stepUpVerified];
}

final class SubmitBorrow implements UseCase<LoanSettlement, SubmitBorrowParams> {
  SubmitBorrow(this._guards, this._borrow);

  final AccessGuards _guards;
  final BorrowRepository _borrow;

  @override
  Future<Either<Failure, LoanSettlement>> call(
    SubmitBorrowParams params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (!params.amount.isPositive) {
      return Either.left(const ValidationFailure('amount_must_be_positive'));
    }
    final stepUp = _guards.requireStepUp(params.stepUpVerified);
    if (stepUp.isLeft()) {
      return stepUp.hideRight();
    }
    final gate = await _guards.requireApproved(ProductArea.borrow);
    if (gate.isLeft()) {
      return gate.hideRight();
    }
    final quote = await _borrow.getQuoteById(params.quoteId);
    return quote.fold<Future<Either<Failure, LoanSettlement>>>(
      (failure) async => Either.left(failure),
      (loaded) async {
        final live = _guards.requireLiveQuote(loaded.freshness);
        if (live.isLeft()) {
          return live.hideRight();
        }
        if (loaded.amount != params.amount || loaded.product != params.product) {
          return Either.left(const ValidationFailure('quote_mismatch'));
        }
        return _borrow.submitBorrow(
          requestId: params.requestId,
          quoteId: params.quoteId,
          product: params.product,
          amount: params.amount,
        );
      },
    );
  }
}

final class SubmitRepayParams extends Equatable {
  const SubmitRepayParams({
    required this.requestId,
    required this.loanId,
    required this.amount,
    required this.stepUpVerified,
  });

  final String requestId;
  final String loanId;
  final Money amount;
  final bool stepUpVerified;

  @override
  List<Object?> get props => [requestId, loanId, amount, stepUpVerified];
}

final class SubmitRepay implements UseCase<LoanSettlement, SubmitRepayParams> {
  SubmitRepay(this._guards, this._borrow);

  final AccessGuards _guards;
  final BorrowRepository _borrow;

  @override
  Future<Either<Failure, LoanSettlement>> call(SubmitRepayParams params) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (params.loanId.isEmpty) {
      return Either.left(const ValidationFailure('loan_id_required'));
    }
    if (!params.amount.isPositive) {
      return Either.left(const ValidationFailure('amount_must_be_positive'));
    }
    final stepUp = _guards.requireStepUp(params.stepUpVerified);
    if (stepUp.isLeft()) {
      return stepUp.hideRight();
    }
    final gate = await _guards.requireApproved(ProductArea.borrow);
    if (gate.isLeft()) {
      return gate.hideRight();
    }
    return _borrow.submitRepay(
      requestId: params.requestId,
      loanId: params.loanId,
      amount: params.amount,
    );
  }
}
