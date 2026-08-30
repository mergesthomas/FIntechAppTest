import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/explore_asset.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_local_datasource.dart';

final class ExploreRepositoryImpl implements ExploreRepository {
  ExploreRepositoryImpl(this._local);

  final ExploreLocalDataSource _local;

  @override
  Future<Either<Failure, List<ExploreAsset>>> getAssets() async {
    return Either.right(_local.assets());
  }
}
