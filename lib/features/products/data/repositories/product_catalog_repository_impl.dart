import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product_tile.dart';
import '../../domain/repositories/product_catalog_repository.dart';
import '../datasources/products_local_datasource.dart';

final class ProductCatalogRepositoryImpl implements ProductCatalogRepository {
  ProductCatalogRepositoryImpl(this._local);

  final ProductsLocalDataSource _local;

  @override
  Future<Either<Failure, List<ProductTile>>> getCatalog({
    required EligibilityStatus eligibility,
  }) async {
    return Either.right(_local.catalog(eligibility: eligibility));
  }
}
