import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/market/require_live_quote.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/futures.dart';
import '../repositories/futures_repository.dart';

final class GetFuturesInstrument
    implements UseCase<FuturesInstrument, NoParams> {
  GetFuturesInstrument(this._session, this._repo);

  final RequireSession _session;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, FuturesInstrument>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getInstrument());
  }
}

final class GetFuturesAccount implements UseCase<FuturesAccount, NoParams> {
  GetFuturesAccount(this._session, this._repo);

  final RequireSession _session;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, FuturesAccount>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getAccount());
  }
}

final class GetOpenPositions
    implements UseCase<List<FuturesPosition>, NoParams> {
  GetOpenPositions(this._session, this._repo);

  final RequireSession _session;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, List<FuturesPosition>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getOpenPositions());
  }
}

final class GetPositionDetails
    implements UseCase<FuturesPositionDetails, String> {
  GetPositionDetails(this._session, this._repo);

  final RequireSession _session;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, FuturesPositionDetails>> call(String id) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getPositionDetails(id));
  }
}

final class GetLastTrades implements UseCase<List<FuturesTrade>, NoParams> {
  GetLastTrades(this._session, this._repo);

  final RequireSession _session;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, List<FuturesTrade>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getLastTrades());
  }
}

final class GetFuturesQuote
    implements UseCase<FuturesQuote, ({FuturesSide side, Money size})> {
  GetFuturesQuote(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, FuturesQuote>> call(
    ({FuturesSide side, Money size}) params,
  ) async {
    if (!params.size.isPositive) {
      return Either.left(const ValidationFailure('amount_required'));
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final status = await _eligibility(const NoParams());
      return status.fold(Either.left, (value) {
        if (value != EligibilityStatus.approved) {
          return Either.left(const EligibilityFailure());
        }
        return _repo.getQuote(side: params.side, size: params.size);
      });
    });
  }
}

final class PreviewFuturesPosition
    implements UseCase<FuturesQuote, ({FuturesSide side, Money size})> {
  PreviewFuturesPosition(this._getQuote);

  final GetFuturesQuote _getQuote;

  @override
  Future<Either<Failure, FuturesQuote>> call(
    ({FuturesSide side, Money size}) params,
  ) {
    return _getQuote(params);
  }
}

final class SubmitFuturesOrder
    implements
        UseCase<
          FuturesSubmit,
          ({String requestId, String quoteId, bool stepUp})
        > {
  SubmitFuturesOrder(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, FuturesSubmit>> call(
    ({String requestId, String quoteId, bool stepUp}) params,
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
            return Either<Failure, FuturesSubmit>.left(
              const StaleQuoteFailure(),
            );
          }
          return _repo.submit(
            requestId: params.requestId,
            quoteId: params.quoteId,
          );
        });
      });
    });
  }
}

final class SetTakeProfitStopLoss
    implements
        UseCase<
          SettlementStatus,
          ({String requestId, String positionId, bool stepUp})
        > {
  SetTakeProfitStopLoss(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({String requestId, String positionId, bool stepUp}) params,
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
        final details = await _repo.getPositionDetails(params.positionId);
        return details.fold(Either.left, (position) {
          if (requireLiveQuote(position.markFreshness).isLeft()) {
            return Either<Failure, SettlementStatus>.left(
              const StaleQuoteFailure(),
            );
          }
          return _repo.setTakeProfitStopLoss(
            requestId: params.requestId,
            positionId: params.positionId,
          );
        });
      });
    });
  }
}

final class ClosePosition
    implements
        UseCase<
          SettlementStatus,
          ({String requestId, String positionId, bool stepUp})
        > {
  ClosePosition(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final FuturesRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({String requestId, String positionId, bool stepUp}) params,
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
      return status.fold(Either.left, (value) {
        if (value != EligibilityStatus.approved) {
          return Either.left(const EligibilityFailure());
        }
        return _repo.closePosition(
          requestId: params.requestId,
          positionId: params.positionId,
        );
      });
    });
  }
}
