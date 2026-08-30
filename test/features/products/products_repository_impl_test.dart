import 'package:fintech_app_test/core/auth/eligibility_status.dart';
import 'package:fintech_app_test/features/products/data/datasources/products_local_datasource.dart';
import 'package:fintech_app_test/features/products/data/repositories/product_catalog_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('denied eligibility disables money-moving tiles', () async {
    final repo = ProductCatalogRepositoryImpl(const ProductsLocalDataSource());

    final denied = await repo.getCatalog(eligibility: EligibilityStatus.denied);
    final tiles = denied.getRight().toNullable()!;

    expect(tiles.firstWhere((t) => t.id == 'credit').enabled, isFalse);
    expect(tiles.firstWhere((t) => t.id == 'explore').enabled, isTrue);
  });
}
