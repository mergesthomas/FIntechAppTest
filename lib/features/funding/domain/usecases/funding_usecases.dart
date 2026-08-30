import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/market/require_live_quote.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/funding.dart';
import '../repositories/funding_repository.dart';

Future<Either<Failure, EligibilityStatus>> _requireApproved(
  GetEligibility eligibility,
) async {
  final result = await eligibility(const NoParams());
  return result.fold(Either.left, (status) {
    if (status != EligibilityStatus.approved) {
      return Either.left(const EligibilityFailure());
    }
    return Either.right(status);
  });
}

final class GetFundingMethods implements UseCase<List<FundingMethod>, NoParams> {
  GetFundingMethods(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, List<FundingMethod>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getMethods());
  }
}

final class GetFiatxAssets implements UseCase<List<FiatxAsset>, NoParams> {
  GetFiatxAssets(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, List<FiatxAsset>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getFiatxAssets());
  }
}

final class GetBankRails implements UseCase<List<BankRail>, Currency> {
  GetBankRails(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, List<BankRail>>> call(Currency asset) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getBankRails(asset));
  }
}

final class GetFiatAccountStatus implements UseCase<FiatAccountStatus, NoParams> {
  GetFiatAccountStatus(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, FiatAccountStatus>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getFiatAccountStatus());
  }
}

final class AcceptFiatAccountTerms implements UseCase<Unit, NoParams> {
  AcceptFiatAccountTerms(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.acceptFiatAccountTerms());
  }
}

final class CreatePersonalUsdAccount
    implements UseCase<SettlementStatus, ({String requestId, bool stepUp})> {
  CreatePersonalUsdAccount(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({String requestId, bool stepUp}) params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (!params.stepUp) {
      return Either.left(const StepUpFailure());
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final eligible = await _requireApproved(_eligibility);
      return eligible.fold(
        Either.left,
        (_) => _repo.createPersonalUsdAccount(requestId: params.requestId),
      );
    });
  }
}

final class GetFiatReceiveDetails
    implements UseCase<FiatReceiveDetails, ({Currency asset, String rail})> {
  GetFiatReceiveDetails(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, FiatReceiveDetails>> call(
    ({Currency asset, String rail}) params,
  ) async {
    final session = await _session(const NoParams());
    return session.fold(
      Either.left,
      (_) => _repo.getFiatReceiveDetails(asset: params.asset, rail: params.rail),
    );
  }
}

final class GetBankTransferFeeSchedule implements UseCase<String, Currency> {
  GetBankTransferFeeSchedule(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, String>> call(Currency asset) async {
    final session = await _session(const NoParams());
    return session.fold(
      Either.left,
      (_) => _repo.getBankTransferFeeSchedule(asset),
    );
  }
}

final class GetReceivableAssets implements UseCase<List<ReceivableAsset>, String> {
  GetReceivableAssets(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, List<ReceivableAsset>>> call(String query) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getReceivableAssets(query));
  }
}

final class GetReceiveAddress implements UseCase<ReceiveAddress, Currency> {
  GetReceiveAddress(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, ReceiveAddress>> call(Currency currency) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getReceiveAddress(currency));
  }
}

final class GetPurchasableAssets
    implements UseCase<List<PurchasableAsset>, String> {
  GetPurchasableAssets(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, List<PurchasableAsset>>> call(String query) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getPurchasableAssets(query));
  }
}

final class GetBuyQuote
    implements UseCase<BuyQuote, ({Currency asset, Money spend})> {
  GetBuyQuote(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, BuyQuote>> call(
    ({Currency asset, Money spend}) params,
  ) async {
    if (!params.spend.isPositive) {
      return Either.left(const ValidationFailure('amount_required'));
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final eligible = await _requireApproved(_eligibility);
      return eligible.fold(
        Either.left,
        (_) => _repo.getBuyQuote(asset: params.asset, spend: params.spend),
      );
    });
  }
}

final class GetPaymentMethods
    implements UseCase<List<PaymentMethodOption>, NoParams> {
  GetPaymentMethods(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, List<PaymentMethodOption>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getPaymentMethods());
  }
}

final class GetPurchaseFrequencies implements UseCase<List<String>, NoParams> {
  GetPurchaseFrequencies(this._session, this._repo);

  final RequireSession _session;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getPurchaseFrequencies());
  }
}

final class SubmitBuyCrypto
    implements
        UseCase<
          BuySubmit,
          ({
            String requestId,
            String quoteId,
            String paymentMethodId,
            Money amount,
            String frequency,
            bool stepUp,
          })
        > {
  SubmitBuyCrypto(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final FundingRepository _repo;

  @override
  Future<Either<Failure, BuySubmit>> call(
    ({
      String requestId,
      String quoteId,
      String paymentMethodId,
      Money amount,
      String frequency,
      bool stepUp,
    }) params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (params.quoteId.isEmpty) {
      return Either.left(const ValidationFailure('quote_id_required'));
    }
    if (!params.amount.isPositive) {
      return Either.left(const ValidationFailure('amount_required'));
    }
    if (!params.stepUp) {
      return Either.left(const StepUpFailure());
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final eligible = await _requireApproved(_eligibility);
      return eligible.fold((failure) async => Either.left(failure), (_) async {
        final quote = await _repo.getBuyQuoteById(params.quoteId);
        return quote.fold(Either.left, (q) {
          final live = requireLiveQuote(q.freshness);
          if (live.isLeft()) {
            return Either<Failure, BuySubmit>.left(const StaleQuoteFailure());
          }
          return _repo.submitBuy(
            requestId: params.requestId,
            quoteId: params.quoteId,
            paymentMethodId: params.paymentMethodId,
            amount: params.amount,
            frequency: params.frequency,
          );
        });
      });
    });
  }
}
