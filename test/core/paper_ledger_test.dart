import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/ledger/paper_ledger.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/paper_harness.dart';

void main() {
  test('posts are confirmed once and idempotent', () async {
    final paper = PaperHarness();
    final order = PaperOrder(
      id: 'ord-1',
      requestId: 'swap-1',
      pair: 'USDC/EURx',
      side: PaperSide.sell,
      status: PaperOrderStatus.open,
      amount: Money.parse('10', Currency.usdc),
      wallet: 'savings',
      venue: PaperVenue.market,
    );
    final first = await paper.ledger.post(
      requestId: 'swap-1',
      lines: [
        LedgerLine(
          book: LedgerBook.savings,
          delta: Money.zero(Currency.usdc) - Money.parse('10', Currency.usdc),
        ),
        LedgerLine(
          book: LedgerBook.savings,
          delta: Money.parse('8', Currency.eurx),
        ),
      ],
      order: order,
    );
    final retry = await paper.ledger.post(
      requestId: 'swap-1',
      lines: [
        LedgerLine(
          book: LedgerBook.savings,
          delta: Money.zero(Currency.usdc) - Money.parse('10', Currency.usdc),
        ),
      ],
      order: order,
    );
    expect(first.getRight().toNullable(), SettlementStatus.confirmed);
    expect(retry.getRight().toNullable(), SettlementStatus.confirmed);
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.usdc),
      Money.parse('9990', Currency.usdc),
    );
    expect(paper.store.all.first.status, PaperOrderStatus.filled);
  });

  test('placeHold debits from and cancelHold restores it', () async {
    final paper = PaperHarness();
    final order = PaperOrder(
      id: 'ord-hold',
      requestId: 'swap-hold',
      pair: 'USDC/DOGE',
      side: PaperSide.sell,
      status: PaperOrderStatus.open,
      amount: Money.parse('10', Currency.usdc),
      wallet: 'savings',
      venue: PaperVenue.limit,
      pay: Currency.usdc,
      receive: Currency.doge,
      limitPrice: Money.parse('0.10', Currency.usdc),
    );
    final placed = await paper.ledger.placeHold(
      requestId: 'swap-hold',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: order,
    );
    expect(placed.getRight().toNullable(), SettlementStatus.confirmed);
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.usdc),
      Money.parse('9990', Currency.usdc),
    );
    expect(paper.store.all.first.status, PaperOrderStatus.open);
    final canceled = await paper.ledger.cancelHold(
      requestId: 'cancel-hold',
      orderId: 'ord-hold',
    );
    expect(canceled.getRight().toNullable(), SettlementStatus.confirmed);
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.usdc),
      Money.parse('10000', Currency.usdc),
    );
    expect(paper.store.all.first.status, PaperOrderStatus.canceled);
  });

  test('fillHold credits receive and marks filled', () async {
    final paper = PaperHarness();
    final order = PaperOrder(
      id: 'ord-fill',
      requestId: 'swap-fill',
      pair: 'USDC/DOGE',
      side: PaperSide.sell,
      status: PaperOrderStatus.open,
      amount: Money.parse('10', Currency.usdc),
      wallet: 'savings',
      venue: PaperVenue.limit,
      pay: Currency.usdc,
      receive: Currency.doge,
    );
    await paper.ledger.placeHold(
      requestId: 'swap-fill',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: order,
    );
    final filled = await paper.ledger.fillHold(
      orderId: 'ord-fill',
      credit: Money.parse('40', Currency.doge),
      book: LedgerBook.savings,
    );
    expect(filled.getRight().toNullable(), SettlementStatus.confirmed);
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.doge),
      Money.parse('10040', Currency.doge),
    );
    expect(paper.store.all.first.status, PaperOrderStatus.filled);
  });

  test('seed records filled card buys including USDC funding before 1Y', () {
    final clock = MutableClock(DateTime.utc(2026, 8, 31));
    final paper = PaperHarness(clock: clock);
    final oneYearAgo = clock.now().subtract(const Duration(days: 365));
    final codes = paper.ledger.lots.map((lot) => lot.currency.code).toSet();

    expect(codes, containsAll(['USDC', 'BTC', 'DOGE', 'PEPE']));
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.usdc),
      Money.parse('10000.00', Currency.usdc),
    );
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.btc),
      Money.parse('0.15', Currency.btc),
    );
    expect(
      paper.store.all.where((order) => order.side == PaperSide.buy),
      isNotEmpty,
    );
    expect(
      paper.store.all
          .where((order) => order.side == PaperSide.buy)
          .every(
            (order) =>
                order.status == PaperOrderStatus.filled &&
                order.filledAt != null,
          ),
      isTrue,
    );
    expect(
      paper.ledger.lots.any(
        (lot) => lot.currency == Currency.usdc && lot.at.isBefore(oneYearAgo),
      ),
      isTrue,
    );
    expect(
      paper.ledger.lots.any(
        (lot) => lot.currency == Currency.btc && lot.at.isBefore(oneYearAgo),
      ),
      isTrue,
    );
  });
}
