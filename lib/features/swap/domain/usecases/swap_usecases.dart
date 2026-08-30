import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/market/require_live_quote.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/swap.dart';
import '../repositories/swap_repository.dart';

final class GetSwapWallets implements UseCase<List<SwapWallet>, NoParams> {
  GetSwapWallets(this._session, this._repo);

  final RequireSession _session;
  final SwapRepository _repo;

  @override
  Future<Either<Failure, List<SwapWallet>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getWallets());
  }
}

final class SearchSwapAssets implements UseCase<List<SwapAsset>, String> {
  SearchSwapAssets(this._session, this._repo);

  final RequireSession _session;
  final SwapRepository _repo;

  @override
  Future<Either<Failure, List<SwapAsset>>> call(String query) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.searchAssets(query));
  }
}

final class GetSwapQuote
    implements
        UseCase<
          SwapQuote,
          ({Currency from, Currency to, Money amount, SwapWallet wallet})
        > {
  GetSwapQuote(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final SwapRepository _repo;

  @override
  Future<Either<Failure, SwapQuote>> call(
    ({Currency from, Currency to, Money amount, SwapWallet wallet}) params,
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
        return _repo.getQuote(
          from: params.from,
          to: params.to,
          amount: params.amount,
          wallet: params.wallet,
        );
      });
    });
  }
}

final class SubmitSwap
    implements
        UseCase<
          SwapSubmit,
          ({String requestId, String quoteId, SwapWallet wallet, bool stepUp})
        > {
  SubmitSwap(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final SwapRepository _repo;

  @override
  Future<Either<Failure, SwapSubmit>> call(
    ({String requestId, String quoteId, SwapWallet wallet, bool stepUp}) params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (!params.stepUp) {
      return Either.left(const StepUpFailure());
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final status = await _eligibility(const NoParams());
      return status.fold((failure) async => Either.left(failure), (value) async {
        if (value != EligibilityStatus.approved) {
          return Either.left(const EligibilityFailure());
        }
        final quote = await _repo.getQuoteById(params.quoteId);
        return quote.fold(Either.left, (q) {
          if (requireLiveQuote(q.freshness).isLeft()) {
            return Either<Failure, SwapSubmit>.left(const StaleQuoteFailure());
          }
          return _repo.submit(
            requestId: params.requestId,
            quoteId: params.quoteId,
            wallet: params.wallet,
          );
        });
      });
    });
  }
}
