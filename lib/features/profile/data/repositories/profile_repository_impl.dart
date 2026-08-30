import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._local);

  final ProfileLocalDataSource _local;

  @override
  Future<Either<Failure, ProfileOverview>> getOverview() async {
    return Either.right(_local.overview());
  }

  @override
  Future<Either<Failure, List<String>>> getRewards() async {
    return Either.right(_local.rewards());
  }

  @override
  Future<Either<Failure, List<ProfileShortcut>>> getShortcuts() async {
    return Either.right(_local.shortcuts());
  }

  @override
  Future<Either<Failure, String>> getAppVersion() async {
    return Either.right(_local.version());
  }

  @override
  Future<Either<Failure, Map<String, String>>> getLegalLinks() async {
    return Either.right(_local.legalLinks());
  }
}
