import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/auth/product_area.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/money/currency.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/bank_transfer.dart';
import '../../repositories/bank_transfer_repository.dart';

final class AcceptFiatAccountTermsParams extends Equatable {
  const AcceptFiatAccountTermsParams({
    required this.asset,
    required this.requestId,
    required this.accepted,
  });

  final Currency asset;
  final String requestId;
  final bool accepted;

  @override
  List<Object?> get props => [asset, requestId, accepted];
}

final class AcceptFiatAccountTerms
    implements UseCase<Unit, AcceptFiatAccountTermsParams> {
  AcceptFiatAccountTerms(this._guards, this._bank);

  final AccessGuards _guards;
  final BankTransferRepository _bank;

  @override
  Future<Either<Failure, Unit>> call(
    AcceptFiatAccountTermsParams params,
  ) async {
    if (!params.accepted) {
      return Either.left(const ValidationFailure('terms_not_accepted'));
    }
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate;
    }
    final result = await _bank.acceptTerms(
      asset: params.asset,
      requestId: params.requestId,
    );
    return result.map((_) => unit);
  }
}

final class CreatePersonalUsdAccountParams extends Equatable {
  const CreatePersonalUsdAccountParams({
    required this.requestId,
    required this.termsAccepted,
    required this.stepUpVerified,
  });

  final String requestId;
  final bool termsAccepted;
  final bool stepUpVerified;

  @override
  List<Object?> get props => [requestId, termsAccepted, stepUpVerified];
}

final class CreatePersonalUsdAccount
    implements UseCase<FundingSettlement, CreatePersonalUsdAccountParams> {
  CreatePersonalUsdAccount(this._guards, this._bank);

  final AccessGuards _guards;
  final BankTransferRepository _bank;

  @override
  Future<Either<Failure, FundingSettlement>> call(
    CreatePersonalUsdAccountParams params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (!params.termsAccepted) {
      return Either.left(const ValidationFailure('terms_not_accepted'));
    }
    final stepUp = _guards.requireStepUp(params.stepUpVerified);
    if (stepUp.isLeft()) {
      return stepUp.hideRight();
    }
    final gate = await _guards.requireApproved(ProductArea.funding);
    if (gate.isLeft()) {
      return gate.hideRight();
    }
    return _bank.createPersonalUsdAccount(requestId: params.requestId);
  }
}
