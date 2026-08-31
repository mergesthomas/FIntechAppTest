import 'dart:async';

import '../error/failure.dart';
import '../market/market_feed.dart';
import '../market/quote_freshness.dart';
import '../market/quote_math.dart';
import '../money/money.dart';
import 'paper_ledger.dart';
import 'paper_order.dart';
import 'resting_fill.dart';

final class PaperFillWatcher {
  PaperFillWatcher({
    required MarketFeed feed,
    required PaperLedger ledger,
  })  : _feed = feed,
        _ledger = ledger {
    _sub = _feed.quotes.listen((_) {
      unawaited(evaluate());
    });
  }

  final MarketFeed _feed;
  final PaperLedger _ledger;
  StreamSubscription<void>? _sub;
  bool _busy = false;

  Future<void> evaluate() async {
    if (_busy) {
      return;
    }
    _busy = true;
    try {
      if (_feed.connection != QuoteFreshness.live) {
        return;
      }
      for (final order in _ledger.orders.openResting) {
        await _tryFill(order);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _tryFill(PaperOrder order) async {
    final pay = order.pay;
    final receive = order.receive;
    if (pay == null || receive == null) {
      return;
    }
    final priced = convertWithFeed(
      feed: _feed,
      from: Money.parse('1', receive),
      to: pay,
    );
    final converted = convertWithFeed(
      feed: _feed,
      from: order.amount,
      to: receive,
    );
    final live = priced.getRight().toNullable();
    final fill = converted.getRight().toNullable();
    if (live == null || fill == null) {
      return;
    }
    if (live.freshness != QuoteFreshness.live ||
        fill.freshness != QuoteFreshness.live) {
      return;
    }
    if (!shouldFillResting(order: order, liveFromPerTo: live.to)) {
      return;
    }
    await _ledger.fillHold(
      orderId: order.id,
      credit: fill.to,
      book: LedgerBook.savings,
    );
  }

  void dispose() {
    unawaited(_sub?.cancel());
  }
}
