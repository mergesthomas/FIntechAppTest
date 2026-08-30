import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/security_settings.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_local_datasource.dart';

final class SecurityRepositoryImpl implements SecurityRepository {
  SecurityRepositoryImpl(this._local);

  final SecurityLocalDataSource _local;

  @override
  Future<Either<Failure, SecuritySnapshot>> getSettings() async {
    return Either.right(_local.settings());
  }

  @override
  Future<Either<Failure, SecuritySnapshot>> setBiometricEnabled(
    bool enabled,
  ) async {
    return Either.right(_local.setBiometric(enabled));
  }

  @override
  Future<Either<Failure, SecuritySnapshot>> setAddressWhitelisting(
    bool enabled,
  ) async {
    return Either.right(_local.setWhitelisting(enabled));
  }

  @override
  Future<Either<Failure, AppPreferences>> getPreferences() async {
    return Either.right(_local.preferences());
  }

  @override
  Future<Either<Failure, SettlementStatus>> closeAccount({
    required String requestId,
    required bool stepUpVerified,
  }) async {
    return Either.right(_local.closeAccount(requestId));
  }

  @override
  Future<Either<Failure, SettlementStatus>> requestDocument({
    required AccountDocumentKind kind,
    required String requestId,
  }) async {
    return Either.right(_local.requestDocument(requestId));
  }
}
