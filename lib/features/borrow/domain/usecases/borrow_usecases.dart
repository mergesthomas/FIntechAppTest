import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/market/require_live_quote.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/borrow.dart';
import '../repositories/borrow_repository.dart';

Future<Either<Failure, Unit>> _gates({
  required RequireSession session,
  required GetEligibility eligibility,
  required bool stepUp,
  required String requestId,
}) async {
  if (requestId.isEmpty) {
    return Either.left(const ValidationFailure('request_id_required'));
  }
  if (!stepUp) {
    return Either.left(const StepUpFailure());
  }
  final restored = await session(const NoParams());
  return restored.fold((failure) async => Either.left(failure), (_) async {
    final status = await eligibility(const NoParams());
    return status.fold(Either.left, (value) {
      if (value != EligibilityStatus.approved) {
        return Either.left(const EligibilityFailure());
      }
      return Either.right(unit);
    });
  });
}

final class GetAllLoansOverview implements UseCase<LoansOverview, NoParams> {
  GetAllLoansOverview(this._session, this._repo);

  final RequireSession _session;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, LoansOverview>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getOverview());
  }
}

final class GetLoanProducts implements UseCase<List<LoanProduct>, NoParams> {
  GetLoanProducts(this._session, this._repo);

  final RequireSession _session;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, List<LoanProduct>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getProducts());
  }
}

final class GetCreditLineOverview implements UseCase<CreditLineOverview, String> {
  GetCreditLineOverview(this._session, this._repo);

  final RequireSession _session;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, CreditLineOverview>> call(String productId) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getCreditLine(productId));
  }
}

final class GetBorrowQuote
    implements UseCase<BorrowQuote, ({String productId, Money amount})> {
  GetBorrowQuote(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, BorrowQuote>> call(
    ({String productId, Money amount}) params,
  ) async {
    if (!params.amount.isPositive) {
      return Either.left(const ValidationFailure('amount_required'));
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final status = await _eligibility(const NoParams());
      return status.fold(Either.left, (value) {
        if (value != EligibilityStatus.approved) {
          return Either.left(const EligibilityFailure());
        }
        return _repo.getBorrowQuote(
          productId: params.productId,
          amount: params.amount,
        );
      });
    });
  }
}

final class SubmitBorrow
    implements
        UseCase<BorrowSubmit, ({String requestId, String quoteId, bool stepUp})> {
  SubmitBorrow(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, BorrowSubmit>> call(
    ({String requestId, String quoteId, bool stepUp}) params,
  ) async {
    final gated = await _gates(
      session: _session,
      eligibility: _eligibility,
      stepUp: params.stepUp,
      requestId: params.requestId,
    );
    return gated.fold((failure) async => Either.left(failure), (_) async {
      if (params.quoteId.isEmpty) {
        return Either.left(const ValidationFailure('quote_id_required'));
      }
      final quote = await _repo.getBorrowQuoteById(params.quoteId);
      return quote.fold(Either.left, (q) {
        if (requireLiveQuote(q.freshness).isLeft()) {
          return Either<Failure, BorrowSubmit>.left(const StaleQuoteFailure());
        }
        return _repo.submitBorrow(
          requestId: params.requestId,
          quoteId: params.quoteId,
        );
      });
    });
  }
}

final class SubmitRepay
    implements
        UseCase<
          BorrowSubmit,
          ({String requestId, String loanId, Money amount, bool stepUp})
        > {
  SubmitRepay(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, BorrowSubmit>> call(
    ({String requestId, String loanId, Money amount, bool stepUp}) params,
  ) async {
    if (!params.amount.isPositive) {
      return Either.left(const ValidationFailure('amount_required'));
    }
    final gated = await _gates(
      session: _session,
      eligibility: _eligibility,
      stepUp: params.stepUp,
      requestId: params.requestId,
    );
    return gated.fold(
      Either.left,
      (_) => _repo.submitRepay(
        requestId: params.requestId,
        loanId: params.loanId,
        amount: params.amount,
      ),
    );
  }
}

final class GetCollateralAssets
    implements UseCase<List<CollateralAsset>, NoParams> {
  GetCollateralAssets(this._session, this._repo);

  final RequireSession _session;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, List<CollateralAsset>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getCollateral());
  }
}

final class GetCreditLineOptimization
    implements UseCase<CreditLineOptimization, NoParams> {
  GetCreditLineOptimization(this._session, this._repo);

  final RequireSession _session;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, CreditLineOptimization>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getOptimization());
  }
}

final class UpdateCreditLineOptimization
    implements
        UseCase<
          SettlementStatus,
          ({String requestId, bool stepUp, CreditLineOptimization flags})
        > {
  UpdateCreditLineOptimization(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final BorrowRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({String requestId, bool stepUp, CreditLineOptimization flags}) params,
  ) async {
    final flags = params.flags;
    if (!flags.automaticCollateralTransfer &&
        (flags.fixedTermUnlock || flags.lowInterestBorrowing)) {
      return Either.left(
        const ValidationFailure('auto_transfer_required_for_dependent_flags'),
      );
    }
    final gated = await _gates(
      session: _session,
      eligibility: _eligibility,
      stepUp: params.stepUp,
      requestId: params.requestId,
    );
    return gated.fold(
      Either.left,
      (_) => _repo.updateOptimization(
        requestId: params.requestId,
        flags: flags,
      ),
    );
  }
}
