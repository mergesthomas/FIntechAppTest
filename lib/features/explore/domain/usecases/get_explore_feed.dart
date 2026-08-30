import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/explore_asset.dart';
import '../repositories/explore_repository.dart';

final class GetExploreFeed implements UseCase<List<ExploreAsset>, NoParams> {
  GetExploreFeed(this._session, this._repo);

  final RequireSession _session;
  final ExploreRepository _repo;

  @override
  Future<Either<Failure, List<ExploreAsset>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getAssets());
  }
}
