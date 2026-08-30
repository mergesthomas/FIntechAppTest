import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/session.dart';
import '../repositories/auth_repository.dart';

final class EnableBiometric implements UseCase<Session, NoParams> {
  EnableBiometric(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Session>> call(NoParams params) {
    return _auth.enableBiometric();
  }
}

final class SkipBiometric implements UseCase<Session, NoParams> {
  SkipBiometric(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Session>> call(NoParams params) {
    return _auth.skipBiometric();
  }
}

final class RestoreSession implements UseCase<Session, NoParams> {
  RestoreSession(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Session>> call(NoParams params) {
    return _auth.restoreSession();
  }
}

final class RequireSession implements UseCase<Session, NoParams> {
  RequireSession(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Session>> call(NoParams params) {
    return _auth.restoreSession();
  }
}

/// Local emulator: a live session means KYC is approved.
final class GetEligibility implements UseCase<EligibilityStatus, NoParams> {
  GetEligibility(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, EligibilityStatus>> call(NoParams params) async {
    final session = await _auth.restoreSession();
    return session.fold(
      Either.left,
      (_) => Either.right(EligibilityStatus.approved),
    );
  }
}

final class LockSession implements UseCase<Unit, NoParams> {
  LockSession(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _auth.lockSession();
  }
}
