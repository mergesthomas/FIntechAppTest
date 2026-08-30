import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/explore_asset.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_local_datasource.dart';

final class ExploreRepositoryImpl implements ExploreRepository {
  ExploreRepositoryImpl(this._local);

  final ExploreLocalDataSource _local;

  @override
  Future<Either<Failure, ExploreFeed>> getFeed() async {
    return Either.right(_local.feed());
  }

  @override
  Future<Either<Failure, List<ExploreAsset>>> getAssets(
    ExploreAssetFilter filter,
  ) async {
    return Either.right(_local.assetsFor(filter));
  }

  @override
  Future<Either<Failure, List<ExploreAsset>>> searchAssets(String query) async {
    return Either.right(_local.search(query));
  }
}
