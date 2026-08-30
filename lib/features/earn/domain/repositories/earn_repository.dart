import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../entities/earn.dart';

abstract class EarnRepository {
  Future<Either<Failure, SavingsHubOverview>> getOverview();
  Future<Either<Failure, List<EarnProductTeaser>>> getProducts();
  Future<Either<Failure, EarnPreference>> getPreference();
  Future<Either<Failure, SettlementStatus>> setEarnInNexo({
    required String requestId,
    required bool enabled,
  });
  Future<Either<Failure, SettlementStatus>> stopEarning({
    required String requestId,
  });
}
