import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/earn.dart';
import '../repositories/earn_repository.dart';

Future<Either<Failure, Unit>> _moneyGate({
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

final class GetSavingsHubOverview
    implements UseCase<SavingsHubOverview, NoParams> {
  GetSavingsHubOverview(this._session, this._repo);

  final RequireSession _session;
  final EarnRepository _repo;

  @override
  Future<Either<Failure, SavingsHubOverview>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getOverview());
  }
}

final class GetEarnProducts
    implements UseCase<List<EarnProductTeaser>, NoParams> {
  GetEarnProducts(this._session, this._repo);

  final RequireSession _session;
  final EarnRepository _repo;

  @override
  Future<Either<Failure, List<EarnProductTeaser>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getProducts());
  }
}

final class GetEarnInNexoPreference
    implements UseCase<EarnPreference, NoParams> {
  GetEarnInNexoPreference(this._session, this._repo);

  final RequireSession _session;
  final EarnRepository _repo;

  @override
  Future<Either<Failure, EarnPreference>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getPreference());
  }
}

final class SetEarnInNexo
    implements
        UseCase<SettlementStatus, ({String requestId, bool enabled, bool stepUp})> {
  SetEarnInNexo(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final EarnRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({String requestId, bool enabled, bool stepUp}) params,
  ) async {
    final gated = await _moneyGate(
      session: _session,
      eligibility: _eligibility,
      stepUp: params.stepUp,
      requestId: params.requestId,
    );
    return gated.fold(
      Either.left,
      (_) => _repo.setEarnInNexo(
        requestId: params.requestId,
        enabled: params.enabled,
      ),
    );
  }
}

final class StopEarning
    implements UseCase<SettlementStatus, ({String requestId, bool stepUp})> {
  StopEarning(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final EarnRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({String requestId, bool stepUp}) params,
  ) async {
    final gated = await _moneyGate(
      session: _session,
      eligibility: _eligibility,
      stepUp: params.stepUp,
      requestId: params.requestId,
    );
    return gated.fold(
      Either.left,
      (_) => _repo.stopEarning(requestId: params.requestId),
    );
  }
}
