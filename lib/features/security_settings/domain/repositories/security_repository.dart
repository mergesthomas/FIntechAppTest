import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../entities/security_settings.dart';

abstract class SecurityRepository {
  Future<Either<Failure, SecuritySnapshot>> getSettings();
  Future<Either<Failure, SecuritySnapshot>> setBiometricEnabled(bool enabled);
  Future<Either<Failure, SecuritySnapshot>> setAddressWhitelisting(bool enabled);
  Future<Either<Failure, AppPreferences>> getPreferences();
  Future<Either<Failure, SettlementStatus>> closeAccount({
    required String requestId,
    required bool stepUpVerified,
  });
  Future<Either<Failure, SettlementStatus>> requestDocument({
    required AccountDocumentKind kind,
    required String requestId,
  });
}
