import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/product_tile.dart';
import '../repositories/product_catalog_repository.dart';

final class GetProductCatalog implements UseCase<List<ProductTile>, NoParams> {
  GetProductCatalog(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final ProductCatalogRepository _repo;

  @override
  Future<Either<Failure, List<ProductTile>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold((failure) async => Either.left(failure), (_) async {
      final eligibility = await _eligibility(params);
      return eligibility.fold(
        Either.left,
        (status) => _repo.getCatalog(eligibility: status),
      );
    });
  }
}
