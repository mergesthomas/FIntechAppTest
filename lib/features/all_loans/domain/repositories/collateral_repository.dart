import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/collateral.dart';
import '../entities/loan_product.dart';

abstract class CollateralRepository {
  Future<Either<Failure, List<CollateralAsset>>> getAssets(
    LoanProductKind creditLine,
  );

  Future<Either<Failure, List<LoanProductKind>>> getFilterOptions();

  Future<Either<Failure, List<AssetLtvEntry>>> getLtvSchedule(
    LoanProductKind creditLine,
  );
}
