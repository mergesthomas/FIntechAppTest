import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/security_settings/data/datasources/security_local_datasource.dart';
import 'package:fintech_app_test/features/security_settings/data/repositories/security_repository_impl.dart';
import 'package:fintech_app_test/features/security_settings/domain/entities/security_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('close account is idempotent inFlight for the same requestId', () async {
    final repo = SecurityRepositoryImpl(SecurityLocalDataSource());

    final first = await repo.closeAccount(
      requestId: 'close-1',
      stepUpVerified: true,
    );
    final retry = await repo.closeAccount(
      requestId: 'close-1',
      stepUpVerified: true,
    );

    expect(first.getRight().toNullable(), SettlementStatus.inFlight);
    expect(retry.getRight().toNullable(), SettlementStatus.inFlight);
  });

  test('document job stays inFlight', () async {
    final repo = SecurityRepositoryImpl(SecurityLocalDataSource());
    final job = await repo.requestDocument(
      kind: AccountDocumentKind.loanStatement,
      requestId: 'doc-1',
    );
    expect(job.getRight().toNullable(), SettlementStatus.inFlight);
  });
}
