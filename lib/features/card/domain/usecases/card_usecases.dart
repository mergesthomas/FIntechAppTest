import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/card.dart';
import '../repositories/card_repository.dart';

final class GetCardStatus implements UseCase<CardSnapshot, NoParams> {
  GetCardStatus(this._session, this._repo);

  final RequireSession _session;
  final CardRepository _repo;

  @override
  Future<Either<Failure, CardSnapshot>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getSnapshot());
  }
}

final class GetCardBalances implements UseCase<CardBalances, NoParams> {
  GetCardBalances(this._session, this._repo);

  final RequireSession _session;
  final CardRepository _repo;

  @override
  Future<Either<Failure, CardBalances>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(
      Either.left,
      (_) async {
        final snapshot = await _repo.getSnapshot();
        return snapshot.map((s) => s.balances);
      },
    );
  }
}

final class RestoreCardBalance implements UseCase<RestoreRail, RestoreRail> {
  RestoreCardBalance(this._session);

  final RequireSession _session;

  @override
  Future<Either<Failure, RestoreRail>> call(RestoreRail rail) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => Either.right(rail));
  }
}

final class UnfreezeCard implements UseCase<CardSnapshot, NoParams> {
  UnfreezeCard(this._session, this._repo);

  final RequireSession _session;
  final CardRepository _repo;

  @override
  Future<Either<Failure, CardSnapshot>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold((failure) async => Either.left(failure), (_) async {
      final snapshot = await _repo.getSnapshot();
      return snapshot.fold(Either.left, (card) {
        if (!card.balances.eligibleToUnfreeze) {
          return Either.left(const ValidationFailure('balance_not_eligible'));
        }
        return _repo.unfreeze();
      });
    });
  }
}
