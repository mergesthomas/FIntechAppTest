import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/ledger/resting_fill.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

PaperOrder _order({
  required PaperVenue venue,
  Money? limit,
  Money? tp,
  Money? sl,
}) {
  return PaperOrder(
    id: 'ord-1',
    requestId: 'r1',
    pair: 'NEXO/DOGE',
    side: PaperSide.sell,
    status: PaperOrderStatus.open,
    amount: Money.parse('10', Currency.nexo),
    wallet: 'savings',
    venue: venue,
    pay: Currency.nexo,
    receive: Currency.doge,
    limitPrice: limit,
    takeProfit: tp,
    stopLoss: sl,
  );
}

void main() {
  final live = Money.parse('0.20', Currency.nexo);

  test('limit fills at or better than limit', () {
    final order = _order(
      venue: PaperVenue.limit,
      limit: Money.parse('0.18', Currency.nexo),
    );
    expect(
      shouldFillResting(order: order, liveFromPerTo: live),
      isFalse,
    );
    expect(
      shouldFillResting(
        order: order,
        liveFromPerTo: Money.parse('0.18', Currency.nexo),
      ),
      isTrue,
    );
    expect(
      shouldFillResting(
        order: order,
        liveFromPerTo: Money.parse('0.10', Currency.nexo),
      ),
      isTrue,
    );
  });

  test('trigger fills on take-profit or stop-loss', () {
    final order = _order(
      venue: PaperVenue.trigger,
      tp: Money.parse('0.15', Currency.nexo),
      sl: Money.parse('0.25', Currency.nexo),
    );
    expect(shouldFillResting(order: order, liveFromPerTo: live), isFalse);
    expect(
      shouldFillResting(
        order: order,
        liveFromPerTo: Money.parse('0.15', Currency.nexo),
      ),
      isTrue,
    );
    expect(
      shouldFillResting(
        order: order,
        liveFromPerTo: Money.parse('0.25', Currency.nexo),
      ),
      isTrue,
    );
  });

  test('market venue never fills as resting', () {
    expect(
      shouldFillResting(
        order: _order(venue: PaperVenue.market),
        liveFromPerTo: live,
      ),
      isFalse,
    );
  });

  test('compares decimals not double', () {
    final order = _order(
      venue: PaperVenue.limit,
      limit: Money.parse('0.20000001', Currency.nexo),
    );
    expect(
      shouldFillResting(order: order, liveFromPerTo: live),
      isTrue,
    );
    expect(live.amount, Decimal.parse('0.20'));
  });
}
