import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/earn/data/datasources/earn_local_datasource.dart';
import 'package:fintech_app_test/features/earn/data/repositories/earn_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stop earning is idempotent inFlight', () async {
    final repo = EarnRepositoryImpl(EarnLocalDataSource());
    final first = await repo.stopEarning(requestId: 'stop-1');
    final retry = await repo.stopEarning(requestId: 'stop-1');
    expect(first.getRight().toNullable(), SettlementStatus.inFlight);
    expect(retry.getRight().toNullable(), SettlementStatus.inFlight);
  });
}
