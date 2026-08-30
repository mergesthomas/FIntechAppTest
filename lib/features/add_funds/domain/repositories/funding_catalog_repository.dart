import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/add_funds_method.dart';

abstract class FundingCatalogRepository {
  Future<Either<Failure, List<AddFundsMethod>>> getMethods();
}
