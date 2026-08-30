import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/auth_port.dart';
import '../../../../../core/auth/eligibility_status.dart';
import '../../../../../core/auth/product_area.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/usecase/use_case.dart';

final class GetFundingEligibility
    implements UseCase<EligibilityStatus, NoParams> {
  GetFundingEligibility(this._auth);

  final AuthPort _auth;

  @override
  Future<Either<Failure, EligibilityStatus>> call(NoParams params) {
    return _auth.eligibility(ProductArea.funding);
  }
}
