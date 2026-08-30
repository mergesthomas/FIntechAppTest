import 'dart:developer' as developer;

import '../settlement/settlement_status.dart';

/// Logs request id + settlement only. Never balances, tokens, or PII.
void logSettlementBreadcrumb({
  required String requestId,
  required SettlementStatus status,
}) {
  developer.log(
    'settlement requestId=$requestId status=${status.name}',
    name: 'ledger',
  );
}
