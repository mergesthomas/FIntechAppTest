import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/inbox_item.dart';
import '../repositories/inbox_repository.dart';

final class GetInboxItems implements UseCase<List<InboxItem>, NoParams> {
  GetInboxItems(this._session, this._repo);

  final RequireSession _session;
  final InboxRepository _repo;

  @override
  Future<Either<Failure, List<InboxItem>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getItems());
  }
}
