import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/explore_asset.dart';
import '../repositories/explore_repository.dart';

final class GetExploreFeed implements UseCase<ExploreFeed, NoParams> {
  GetExploreFeed(this._session, this._repo);

  final RequireSession _session;
  final ExploreRepository _repo;

  @override
  Future<Either<Failure, ExploreFeed>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getFeed());
  }
}

final class GetMarketAssets
    implements UseCase<List<ExploreAsset>, ExploreAssetFilter> {
  GetMarketAssets(this._session, this._repo);

  final RequireSession _session;
  final ExploreRepository _repo;

  @override
  Future<Either<Failure, List<ExploreAsset>>> call(
    ExploreAssetFilter filter,
  ) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getAssets(filter));
  }
}

final class SearchExploreAssets implements UseCase<List<ExploreAsset>, String> {
  SearchExploreAssets(this._session, this._repo);

  final RequireSession _session;
  final ExploreRepository _repo;

  @override
  Future<Either<Failure, List<ExploreAsset>>> call(String query) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.searchAssets(query));
  }
}
