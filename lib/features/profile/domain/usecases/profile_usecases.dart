import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

final class GetProfileOverview implements UseCase<ProfileOverview, NoParams> {
  GetProfileOverview(this._session, this._repo);

  final RequireSession _session;
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, ProfileOverview>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getOverview());
  }
}

final class GetRewardsTeasers implements UseCase<List<String>, NoParams> {
  GetRewardsTeasers(this._session, this._repo);

  final RequireSession _session;
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getRewards());
  }
}

final class GetProfileProductShortcuts
    implements UseCase<List<ProfileShortcut>, NoParams> {
  GetProfileProductShortcuts(this._session, this._repo);

  final RequireSession _session;
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, List<ProfileShortcut>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getShortcuts());
  }
}

final class GetAppVersionInfo implements UseCase<String, NoParams> {
  GetAppVersionInfo(this._session, this._repo);

  final RequireSession _session;
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getAppVersion());
  }
}

final class GetLegalLinks implements UseCase<Map<String, String>, NoParams> {
  GetLegalLinks(this._session, this._repo);

  final RequireSession _session;
  final ProfileRepository _repo;

  @override
  Future<Either<Failure, Map<String, String>>> call(NoParams params) async {
    final session = await _session(params);
    return session.fold(Either.left, (_) => _repo.getLegalLinks());
  }
}
