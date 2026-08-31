import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/market/require_live_quote.dart';
import '../../../../core/money/currency.dart';
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

final class GetSwapOrderTypes
    implements UseCase<List<SwapOrderType>, NoParams> {
  GetSwapOrderTypes(this._session);

  final RequireSession _session;

  @override
  Future<Either<Failure, List<SwapOrderType>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(
      Either.left,
      (_) => Either.right(SwapOrderType.values),
    );
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

final class WatchSwapRate {
  WatchSwapRate(this._session, this._repo);

  final RequireSession _session;
  final SwapRepository _repo;

  Stream<Either<Failure, SwapRate>> call(
    ({Currency from, Currency to}) params,
  ) async* {
    final session = await _session(const NoParams());
    if (session.isLeft()) {
      yield Either.left(
        session.fold((failure) => failure, (_) => const SessionFailure()),
      );
      return;
    }
    yield* _repo.watchRate(from: params.from, to: params.to);
  }
}

final class GetSwapQuote
    implements UseCase<SwapQuote, SwapQuoteRequest> {
  GetSwapQuote(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final SwapRepository _repo;

  @override
  Future<Either<Failure, SwapQuote>> call(SwapQuoteRequest params) async {
    final shape = _validateShape(params);
    if (shape != null) {
      return Either.left(shape);
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final status = await _eligibility(const NoParams());
      return status.fold((failure) async => Either.left(failure), (value) async {
        if (value != EligibilityStatus.approved) {
          return Either.left(const EligibilityFailure());
        }
        final quoted = await _repo.getQuote(params);
        return quoted.fold(Either.left, (quote) {
          final market = _validateVsMarket(params, quote);
          if (market != null) {
            return Either.left(market);
          }
          return Either.right(quote);
        });
      });
    });
  }

  Failure? _validateShape(SwapQuoteRequest params) {
    if (!params.amount.isPositive) {
      return const ValidationFailure('amount_required');
    }
    if (params.from == params.to) {
      return const ValidationFailure('pair_invalid');
    }
    switch (params.type) {
      case SwapOrderType.instant:
        return null;
      case SwapOrderType.limit:
        final limit = params.limitPrice;
        if (limit == null || !limit.isPositive) {
          return const ValidationFailure('limit_required');
        }
        if (limit.currency != params.from) {
          return const ValidationFailure('price_currency_mismatch');
        }
        return null;
      case SwapOrderType.trigger:
        final tp = params.takeProfit;
        final sl = params.stopLoss;
        if ((tp == null || !tp.isPositive) && (sl == null || !sl.isPositive)) {
          return const ValidationFailure('trigger_price_required');
        }
        if (tp != null && tp.currency != params.from) {
          return const ValidationFailure('price_currency_mismatch');
        }
        if (sl != null && sl.currency != params.from) {
          return const ValidationFailure('price_currency_mismatch');
        }
        return null;
    }
  }

  Failure? _validateVsMarket(SwapQuoteRequest params, SwapQuote quote) {
    final live = quote.rateFromPerTo;
    switch (params.type) {
      case SwapOrderType.instant:
        return null;
      case SwapOrderType.limit:
        final limit = params.limitPrice!;
        if (limit.amount >= live.amount) {
          return const ValidationFailure('limit_not_better');
        }
        return null;
      case SwapOrderType.trigger:
        final tp = params.takeProfit;
        final sl = params.stopLoss;
        if (tp != null && tp.isPositive && tp.amount >= live.amount) {
          return const ValidationFailure('take_profit_not_better');
        }
        if (sl != null && sl.isPositive && sl.amount <= live.amount) {
          return const ValidationFailure('stop_loss_not_worse');
        }
        return null;
    }
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
