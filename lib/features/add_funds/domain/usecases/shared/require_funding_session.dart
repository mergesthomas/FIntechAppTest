import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/use_case.dart';

final class RequireFundingSession implements UseCase<Unit, NoParams> {
  RequireFundingSession(this._guards);

  final AccessGuards _guards;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _guards.requireSession();
  }
}
