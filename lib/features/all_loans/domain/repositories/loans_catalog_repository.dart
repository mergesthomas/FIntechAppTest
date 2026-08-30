import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/loan_product.dart';

abstract class LoansCatalogRepository {
  Future<Either<Failure, AllLoansOverview>> getOverview();

  Future<Either<Failure, List<LoanProduct>>> getProducts();
}
