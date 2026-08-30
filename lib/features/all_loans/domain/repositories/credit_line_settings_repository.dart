import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/credit_line_optimization.dart';
import '../entities/loan_product.dart';

abstract class CreditLineSettingsRepository {
  Future<Either<Failure, CreditLineOptimization>> getSettings(
    LoanProductKind product,
  );

  Future<Either<Failure, LoanSettlement>> updateSettings({
    required String requestId,
    required CreditLineOptimization settings,
  });
}
