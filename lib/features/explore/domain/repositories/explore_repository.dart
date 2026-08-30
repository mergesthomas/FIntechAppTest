import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/explore_asset.dart';

abstract class ExploreRepository {
  Future<Either<Failure, ExploreFeed>> getFeed();
  Future<Either<Failure, List<ExploreAsset>>> getAssets(ExploreAssetFilter filter);
  Future<Either<Failure, List<ExploreAsset>>> searchAssets(String query);
}
