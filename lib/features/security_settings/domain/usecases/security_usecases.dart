import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/security_settings.dart';
import '../repositories/security_repository.dart';

final class GetSecuritySettings implements UseCase<SecuritySnapshot, NoParams> {
  GetSecuritySettings(this._session, this._repo);

  final RequireSession _session;
  final SecurityRepository _repo;

  @override
  Future<Either<Failure, SecuritySnapshot>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getSettings());
  }
}

final class SetBiometricEnabled implements UseCase<SecuritySnapshot, bool> {
  SetBiometricEnabled(this._session, this._repo);

  final RequireSession _session;
  final SecurityRepository _repo;

  @override
  Future<Either<Failure, SecuritySnapshot>> call(bool enabled) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.setBiometricEnabled(enabled));
  }
}

final class SetAddressWhitelisting implements UseCase<SecuritySnapshot, bool> {
  SetAddressWhitelisting(this._session, this._repo);

  final RequireSession _session;
  final SecurityRepository _repo;

  @override
  Future<Either<Failure, SecuritySnapshot>> call(bool enabled) async {
    final session = await _session(const NoParams());
    return session.fold(
      Either.left,
      (_) => _repo.setAddressWhitelisting(enabled),
    );
  }
}

final class GetAppPreferences implements UseCase<AppPreferences, NoParams> {
  GetAppPreferences(this._session, this._repo);

  final RequireSession _session;
  final SecurityRepository _repo;

  @override
  Future<Either<Failure, AppPreferences>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getPreferences());
  }
}

final class Logout implements UseCase<Unit, NoParams> {
  Logout(this._lock);

  final LockSession _lock;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _lock(params);
}

final class StartCloseAccount
    implements UseCase<SettlementStatus, ({String requestId, bool stepUp})> {
  StartCloseAccount(this._session, this._repo);

  final RequireSession _session;
  final SecurityRepository _repo;

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
    return session.fold(
      Either.left,
      (_) => _repo.closeAccount(
        requestId: params.requestId,
        stepUpVerified: params.stepUp,
      ),
    );
  }
}

final class RequestAccountDocument
    implements
        UseCase<SettlementStatus, ({AccountDocumentKind kind, String requestId})> {
  RequestAccountDocument(this._session, this._repo);

  final RequireSession _session;
  final SecurityRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({AccountDocumentKind kind, String requestId}) params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    final session = await _session(const NoParams());
    return session.fold(
      Either.left,
      (_) => _repo.requestDocument(
        kind: params.kind,
        requestId: params.requestId,
      ),
    );
  }
}
