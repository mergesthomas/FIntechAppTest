import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileOverview>> getOverview();
  Future<Either<Failure, List<String>>> getRewards();
  Future<Either<Failure, List<ProfileShortcut>>> getShortcuts();
  Future<Either<Failure, String>> getAppVersion();
  Future<Either<Failure, Map<String, String>>> getLegalLinks();
}
