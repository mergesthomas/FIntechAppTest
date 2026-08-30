import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import 'eligibility_status.dart';
import 'product_area.dart';

/// Session and KYC live outside features. Tokens never enter Domain.
abstract class AuthPort {
  Future<Either<Failure, bool>> hasValidSession();

  Future<Either<Failure, EligibilityStatus>> eligibility(ProductArea area);
}
