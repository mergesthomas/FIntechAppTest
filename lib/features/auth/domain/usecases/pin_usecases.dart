import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/pin_draft.dart';
import '../repositories/auth_repository.dart';

final class CreatePin implements UseCase<PinDraft, String> {
  CreatePin(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, PinDraft>> call(String pin) {
    if (!_isFourDigits(pin)) {
      return Future.value(
        Either.left(const ValidationFailure('pin_must_be_4_digits')),
      );
    }
    return _auth.createPin(pin);
  }
}

final class ConfirmPinParams extends Equatable {
  const ConfirmPinParams({required this.draft, required this.pin});

  final PinDraft draft;
  final String pin;

  @override
  List<Object?> get props => [draft, pin];
}

final class ConfirmPin implements UseCase<Unit, ConfirmPinParams> {
  ConfirmPin(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Unit>> call(ConfirmPinParams params) {
    if (!_isFourDigits(params.pin)) {
      return Future.value(
        Either.left(const ValidationFailure('pin_must_be_4_digits')),
      );
    }
    return _auth.confirmPin(draft: params.draft, pin: params.pin);
  }
}

final class ResetPinDraft implements UseCase<Unit, NoParams> {
  ResetPinDraft(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _auth.resetPinDraft();
  }
}

bool _isFourDigits(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);
