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
  static const info = 'Paper swap using public prices. Not a broker.';
  static const feeInfo = 'COMPLIANCE: fee schedule pending review.';
  static const cashbackInfo = 'COMPLIANCE: cashback pending review.';
  static const placed = 'Order placed';
  static const noAssets = 'No swap assets';
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
}
