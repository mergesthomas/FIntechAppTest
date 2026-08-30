import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/auth/product_area.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/bank_transfer.dart';
import '../../entities/buy_crypto.dart';
import '../../repositories/buy_crypto_repository.dart';

final class StartLinkCardParams extends Equatable {
  const StartLinkCardParams({
    required this.requestId,
    required this.stepUpVerified,
  });

  final String requestId;
  final bool stepUpVerified;

  @override
  List<Object?> get props => [requestId, stepUpVerified];
}

final class StartLinkCard implements UseCase<LinkCardSession, StartLinkCardParams> {
  StartLinkCard(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, LinkCardSession>> call(
    StartLinkCardParams params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    final stepUp = _guards.requireStepUp(params.stepUpVerified);
    if (stepUp.isLeft()) {
      return stepUp.hideRight();
    }
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate.hideRight();
    }
    return _buy.startLinkCard(requestId: params.requestId);
  }
}

final class SubmitBuyCryptoParams extends Equatable {
  const SubmitBuyCryptoParams({
    required this.requestId,
    required this.quoteId,
    required this.paymentMethodId,
    required this.amount,
    required this.frequency,
    required this.stepUpVerified,
  });

  final String requestId;
  final String quoteId;
  final String paymentMethodId;
  final Money amount;
  final PurchaseFrequency frequency;
  final bool stepUpVerified;

  @override
  List<Object?> get props => [
        requestId,
        quoteId,
        paymentMethodId,
        amount,
        frequency,
        stepUpVerified,
      ];
}

final class SubmitBuyCrypto
    implements UseCase<FundingSettlement, SubmitBuyCryptoParams> {
  SubmitBuyCrypto(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, FundingSettlement>> call(
    SubmitBuyCryptoParams params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (params.quoteId.isEmpty) {
      return Either.left(const ValidationFailure('quote_id_required'));
    }
    if (!params.amount.isPositive) {
      return Either.left(const ValidationFailure('amount_must_be_positive'));
    }
    final stepUp = _guards.requireStepUp(params.stepUpVerified);
    if (stepUp.isLeft()) {
      return stepUp.hideRight();
    }
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate.hideRight();
    }
    final quote = await _buy.getQuoteById(params.quoteId);
    return quote.fold<Future<Either<Failure, FundingSettlement>>>(
      (failure) async => Either.left(failure),
      (loaded) async {
        final live = _guards.requireLiveQuote(loaded.freshness);
        if (live.isLeft()) {
          return live.hideRight();
        }
        if (loaded.fiatIn != params.amount) {
          return Either.left(
            const ValidationFailure('amount_does_not_match_quote'),
          );
        }
        return _buy.submitBuy(
          requestId: params.requestId,
          quoteId: params.quoteId,
          paymentMethodId: params.paymentMethodId,
          amount: params.amount,
          frequency: params.frequency,
        );
      },
    );
  }
}
