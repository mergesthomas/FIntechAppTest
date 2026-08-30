import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/auth/auth_port.dart';
import '../../../../../core/auth/eligibility_status.dart';
import '../../../../../core/auth/product_area.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/use_case.dart';

final class RequireBorrowSession implements UseCase<Unit, NoParams> {
  RequireBorrowSession(this._guards);

  final AccessGuards _guards;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _guards.requireSession();
  }
}

final class GetBorrowEligibility
    implements UseCase<EligibilityStatus, NoParams> {
  GetBorrowEligibility(this._auth);

  final AuthPort _auth;

  @override
  Future<Either<Failure, EligibilityStatus>> call(NoParams params) {
    return _auth.eligibility(ProductArea.borrow);
  }
}
