import '../../../../core/settlement/settlement_status.dart';

/// Swap copy. Fee and cashback are screenshot placeholders — COMPLIANCE review.
abstract final class SwapCopy {
  static const title = 'Swap';
  static const previewTitle = 'Preview order';
  static const previewCta = 'Preview order';
  static const confirmCta = 'Confirm order';
  static const receive = 'Receive';
  static const payWith = 'Pay with';
  static const orderType = 'Order type';
  static const exchangeRate = 'Exchange rate';
  static const feeApplied = 'Fee applied';
  static const feeValue = '0.99 USD';
  static const cashbackLabel = 'Cashback included (0.50%)';
  static const cashbackRate = '0.005';
  static const instant = 'Instant';
  static const instantOrder = 'Instant order';
  static const limit = 'Limit';
  static const limitOrder = 'Limit order';
  static const trigger = 'Trigger';
  static const triggerOrder = 'Trigger order';
  static const limitPrice = 'Limit price';
  static const takeProfit = 'Take profit price';
  static const stopLoss = 'Stop loss price';
  static const setPrice = '+ Set';
  static const orders = 'Orders';
  static const viewOrders = 'View orders';
  static const done = 'Done';
  static const status = 'Status';
  static const info = 'Paper swap using public prices. Not a broker.';
  static const feeInfo = 'COMPLIANCE: fee schedule pending review.';
  static const cashbackInfo = 'COMPLIANCE: cashback pending review.';
  static const confirmed = 'Swap confirmed';
  static const placed = 'Order placed';
  static const inProgress = 'Settlement in progress';
  static const failed = 'Swap failed';
  static const unknownStatus = 'Status unknown';
  static const noAssets = 'No swap assets';
  static const staleQuote = 'Quote is stale — swap rejected';
  static const stepUpRequired = 'Step-up required';
  static const pct10 = '10%';
  static const pct20 = '20%';
  static const pct30 = '30%';
  static const pct50 = '50%';
  static const pctMax = 'Max';

  static String orderTypeLabel(String name) {
    return switch (name) {
      'instant' => instantOrder,
      'limit' => limitOrder,
      'trigger' => triggerOrder,
      _ => name,
    };
  }

  static String settlementHeadline({
    required SettlementStatus settlement,
    required bool resting,
  }) {
    return switch (settlement) {
      SettlementStatus.confirmed => resting ? placed : confirmed,
      SettlementStatus.inFlight => inProgress,
      SettlementStatus.failed => failed,
      SettlementStatus.unknown => unknownStatus,
    };
  }

  static String settlementStatus(SettlementStatus settlement) {
    return switch (settlement) {
      SettlementStatus.confirmed => 'Confirmed',
      SettlementStatus.inFlight => 'In progress',
      SettlementStatus.failed => 'Failed',
      SettlementStatus.unknown => 'Unknown',
    };
  }
}
