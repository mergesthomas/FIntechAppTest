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
      pair: 'NEXO/EURx',
      side: PaperSide.sell,
      status: PaperOrderStatus.open,
      amount: Money.parse('10', Currency.nexo),
      wallet: 'savings',
      venue: PaperVenue.market,
    );
    final first = await paper.ledger.post(
      requestId: 'swap-1',
      lines: [
        LedgerLine(
          book: LedgerBook.savings,
          delta: Money.zero(Currency.nexo) - Money.parse('10', Currency.nexo),
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
          delta: Money.zero(Currency.nexo) - Money.parse('10', Currency.nexo),
        ),
      ],
      order: order,
    );
    expect(first.getRight().toNullable(), SettlementStatus.confirmed);
    expect(retry.getRight().toNullable(), SettlementStatus.confirmed);
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.nexo),
      Money.parse('110', Currency.nexo),
    );
    expect(paper.store.all.first.status, PaperOrderStatus.filled);
  });
}
