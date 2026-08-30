import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/earn.dart';
import '../../domain/repositories/earn_repository.dart';
import '../datasources/earn_local_datasource.dart';

final class EarnRepositoryImpl implements EarnRepository {
  EarnRepositoryImpl(this._local);

  final EarnLocalDataSource _local;

  @override
  Future<Either<Failure, SavingsHubOverview>> getOverview() async {
    return Either.right(_local.overview());
  }

  @override
  Future<Either<Failure, List<EarnProductTeaser>>> getProducts() async {
    return Either.right(_local.products());
  }

  @override
  Future<Either<Failure, EarnPreference>> getPreference() async {
    return Either.right(_local.preference());
  }

  @override
  Future<Either<Failure, SettlementStatus>> setEarnInNexo({
    required String requestId,
    required bool enabled,
  }) async {
    return Either.right(
      _local.setEarnInNexo(requestId: requestId, enabled: enabled),
    );
  }

  @override
  Future<Either<Failure, SettlementStatus>> stopEarning({
    required String requestId,
  }) async {
    return Either.right(_local.stop(requestId: requestId));
  }
}
