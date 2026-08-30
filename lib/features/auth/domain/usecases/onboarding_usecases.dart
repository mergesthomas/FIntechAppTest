import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../entities/onboarding_slide.dart';
import '../repositories/auth_repository.dart';

final class GetOnboardingSlides
    implements UseCase<List<OnboardingSlide>, NoParams> {
  GetOnboardingSlides(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, List<OnboardingSlide>>> call(NoParams params) {
    return _auth.getOnboardingSlides();
  }
}

final class GetPreferredLocale implements UseCase<String, NoParams> {
  GetPreferredLocale(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, String>> call(NoParams params) {
    return _auth.getPreferredLocale();
  }
}

final class SetPreferredLocale implements UseCase<Unit, String> {
  SetPreferredLocale(this._auth);

  final AuthRepository _auth;

  @override
  Future<Either<Failure, Unit>> call(String locale) {
    if (locale.trim().isEmpty) {
      return Future.value(
        Either.left(const ValidationFailure('locale_required')),
      );
    }
    return _auth.setPreferredLocale(locale.trim());
  }
}
