import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/auth/product_area.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/credit_line_optimization.dart';
import '../../entities/loan_product.dart';
import '../../repositories/credit_line_settings_repository.dart';

final class GetCreditLineOptimization
    implements UseCase<CreditLineOptimization, LoanProductKind> {
  GetCreditLineOptimization(this._guards, this._settings);

  final AccessGuards _guards;
  final CreditLineSettingsRepository _settings;

  @override
  Future<Either<Failure, CreditLineOptimization>> call(
    LoanProductKind product,
  ) async {
    if (product != LoanProductKind.classic && product != LoanProductKind.card) {
      return Either.left(const ValidationFailure('unsupported_credit_line'));
    }
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _settings.getSettings(product);
  }
}

final class UpdateCreditLineOptimizationParams extends Equatable {
  const UpdateCreditLineOptimizationParams({
    required this.requestId,
    required this.settings,
    required this.stepUpVerified,
  });

  final String requestId;
  final CreditLineOptimization settings;
  final bool stepUpVerified;

  @override
  List<Object?> get props => [requestId, settings, stepUpVerified];
}

final class UpdateCreditLineOptimization
    implements UseCase<LoanSettlement, UpdateCreditLineOptimizationParams> {
  UpdateCreditLineOptimization(this._guards, this._settings);

  final AccessGuards _guards;
  final CreditLineSettingsRepository _settings;

  @override
  Future<Either<Failure, LoanSettlement>> call(
    UpdateCreditLineOptimizationParams params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (params.settings.product != LoanProductKind.classic &&
        params.settings.product != LoanProductKind.card) {
      return Either.left(const ValidationFailure('unsupported_credit_line'));
    }
    if (!params.settings.isLegalCombination) {
      return Either.left(
        const ValidationFailure('requires_automatic_collateral_transfer'),
      );
    }
    final stepUp = _guards.requireStepUp(params.stepUpVerified);
    if (stepUp.isLeft()) {
      return stepUp.hideRight();
    }
    final gate = await _guards.requireApproved(ProductArea.borrow);
    if (gate.isLeft()) {
      return gate.hideRight();
    }
    return _settings.updateSettings(
      requestId: params.requestId,
      settings: params.settings,
    );
  }
}
