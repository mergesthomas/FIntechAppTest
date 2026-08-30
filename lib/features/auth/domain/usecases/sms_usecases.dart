import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/pending_auth.dart';
import '../repositories/auth_repository.dart';

final class StartLogin implements UseCase<PendingAuth, String> {
  StartLogin(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, PendingAuth>> call(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      return Future.value(
        Either.left(const ValidationFailure('invalid_phone')),
      );
    }
    return _auth.startLogin(normalized);
  }
}

final class StartSignUp implements UseCase<PendingAuth, String> {
  StartSignUp(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, PendingAuth>> call(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized == null) {
      return Future.value(
        Either.left(const ValidationFailure('invalid_phone')),
      );
    }
    return _auth.startSignUp(normalized);
  }
}

final class ResendSms implements UseCase<PendingAuth, NoParams> {
  ResendSms(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, PendingAuth>> call(NoParams params) {
    return _auth.resendSms();
  }
}

final class VerifySmsCode implements UseCase<Unit, String> {
  VerifySmsCode(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Unit>> call(String code) {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      return Future.value(
        Either.left(const ValidationFailure('sms_code_must_be_6_digits')),
      );
    }
    return _auth.verifySmsCode(digits);
  }
}

String? _normalizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8) {
    return null;
  }
  return digits;
}
