import '../money/money.dart';
import 'paper_order.dart';

/// [liveFromPerTo] is the live price of 1 receive unit in the pay currency.
bool shouldFillResting({
  required PaperOrder order,
  required Money liveFromPerTo,
}) {
  if (order.status != PaperOrderStatus.open) {
    return false;
  }
  return switch (order.venue) {
    PaperVenue.market => false,
    PaperVenue.limit => _atOrBetter(order.limitPrice, liveFromPerTo),
    PaperVenue.trigger =>
      _atOrBetter(order.takeProfit, liveFromPerTo) ||
          _atOrWorse(order.stopLoss, liveFromPerTo),
  };
}

bool _atOrBetter(Money? target, Money live) {
  if (target == null || target.currency != live.currency) {
    return false;
  }
  return live.amount <= target.amount;
}

bool _atOrWorse(Money? target, Money live) {
  if (target == null || target.currency != live.currency) {
    return false;
  }
  return live.amount >= target.amount;
}
