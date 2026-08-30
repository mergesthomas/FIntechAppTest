/// Ledger settlement. HTTP 200 is never treated as [confirmed].
enum SettlementStatus { inFlight, unknown, confirmed, failed }
