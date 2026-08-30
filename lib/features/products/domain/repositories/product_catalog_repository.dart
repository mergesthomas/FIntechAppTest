import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../entities/product_tile.dart';

abstract class ProductCatalogRepository {
  Future<Either<Failure, List<ProductTile>>> getCatalog({
    required EligibilityStatus eligibility,
  });
}
