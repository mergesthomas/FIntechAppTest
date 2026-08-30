import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/explore_asset.dart';

abstract class ExploreRepository {
  Future<Either<Failure, List<ExploreAsset>>> getAssets();
}
