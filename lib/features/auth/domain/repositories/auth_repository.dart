import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/onboarding_slide.dart';
import '../entities/pending_auth.dart';
import '../entities/pin_draft.dart';
import '../entities/session.dart';

abstract class AuthRepository {
  Future<Either<Failure, List<OnboardingSlide>>> getOnboardingSlides();

  Future<Either<Failure, String>> getPreferredLocale();

  Future<Either<Failure, Unit>> setPreferredLocale(String locale);

  Future<Either<Failure, PendingAuth>> startLogin(String phone);

  Future<Either<Failure, PendingAuth>> startSignUp(String phone);

  Future<Either<Failure, PendingAuth>> resendSms();

  Future<Either<Failure, Unit>> verifySmsCode(String code);

  Future<Either<Failure, PinDraft>> createPin(String pin);

  Future<Either<Failure, Unit>> confirmPin({
    required PinDraft draft,
    required String pin,
  });

  Future<Either<Failure, Unit>> resetPinDraft();

  Future<Either<Failure, Session>> enableBiometric();

  Future<Either<Failure, Session>> skipBiometric();

  Future<Either<Failure, Session>> restoreSession();

  Future<Either<Failure, Unit>> lockSession();
}
