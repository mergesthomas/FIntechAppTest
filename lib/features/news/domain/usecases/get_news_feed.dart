import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/news_item.dart';
import '../repositories/news_repository.dart';

final class GetNewsFeed implements UseCase<List<NewsItem>, NoParams> {
  GetNewsFeed(this._session, this._repo);

  final RequireSession _session;
  final NewsRepository _repo;

  @override
  Future<Either<Failure, List<NewsItem>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getFeed());
  }
}
