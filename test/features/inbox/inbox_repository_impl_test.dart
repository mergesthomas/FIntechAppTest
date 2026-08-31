import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/ledger/paper_ledger.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/ledger/portfolio_chart.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/inbox/data/datasources/inbox_local_datasource.dart';
import 'package:fintech_app_test/features/inbox/data/inbox_unit_price.dart';
import 'package:fintech_app_test/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:fintech_app_test/features/inbox/domain/entities/inbox_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';

void main() {
  final clock = MutableClock(DateTime.utc(2026, 8, 31));

  InboxRepositoryImpl repo(PaperHarness paper) {
    return InboxRepositoryImpl(
      InboxLocalDataSource(
        store: paper.store,
        feed: paper.feed,
        clock: clock,
      ),
    );
  }

  test('lists seeded buys as Money, newest first, without interest', () async {
    final paper = PaperHarness(clock: clock);
    final items = (await repo(paper).getItems()).getRight().toNullable()!;
    final titles = items.map((item) => item.title).toList();

    expect(titles, isNot(contains('Interest Earned')));
    expect(
      titles,
      containsAll([
        'Bought BTC',
        'Bought USDC',
        'Bought DOGE',
        'Bought PEPE',
      ]),
    );
    expect(items.first.title, 'Bought PEPE');
    expect(
      items.where((item) => item.kind == InboxItemKind.buy).length,
      4,
    );
    expect(
      items.firstWhere((item) => item.title == 'Bought BTC').amount,
      Money.parse('0.15', Currency.btc),
    );
  });

  test('buy rows use the USD unit price on the fill day', () async {
    final paper = PaperHarness(clock: clock);
    final items = (await repo(paper).getItems()).getRight().toNullable()!;
    final btc = items.firstWhere((item) => item.title == 'Bought BTC');
    final now = clock.now().toUtc();
    final live = paper.feed.usdPrice(Currency.btc)!;
    final series = paper.feed.seriesFor(Currency.btc, ChartPeriod.all);
    final expected = seriesRateAt(
      closes: series.closes,
      start: now.subtract(inboxPriceLookback),
      end: now,
      at: btc.occurredAt,
      fallback: live.amount,
    );

    expect(btc.unitPrice, Money.fromDecimal(expected, Currency.usd));
    expect(btc.unitPrice, isNot(live));
    expect(
      items.firstWhere((item) => item.title == 'Bought USDC').unitPrice,
      isNotNull,
    );
    expect(
      items
          .firstWhere((item) => item.title == 'Bought USDC')
          .unitPrice!
          .currency,
      Currency.usd,
    );
  });

  test('includes filled swaps and skips open holds', () async {
    final paper = PaperHarness(clock: clock);
    await paper.ledger.post(
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
      order: PaperOrder(
        id: 'ord-swap-1',
        requestId: 'swap-1',
        pair: 'USDC/EURx',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: Money.parse('10', Currency.usdc),
        wallet: 'savings',
        venue: PaperVenue.market,
        pay: Currency.usdc,
        receive: Currency.eurx,
      ),
    );
    await paper.ledger.placeHold(
      requestId: 'swap-hold',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
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
      ),
    );

    final items = (await repo(paper).getItems()).getRight().toNullable()!;
    expect(
      items.any((item) => item.title == 'Swapped USDC to EURx'),
      isTrue,
    );
    expect(items.any((item) => item.id == 'ord-hold'), isFalse);
    expect(
      items.firstWhere((item) => item.id == 'ord-swap-1').kind,
      InboxItemKind.swap,
    );
    expect(
      items.firstWhere((item) => item.id == 'ord-swap-1').requestId,
      'swap-1',
    );
    expect(
      items.firstWhere((item) => item.id == 'ord-swap-1').unitPrice,
      isNotNull,
    );
  });

  test('includes canceled and filled resting orders', () async {
    final paper = PaperHarness(clock: clock);
    await paper.ledger.placeHold(
      requestId: 'swap-cancel',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
        id: 'ord-cancel',
        requestId: 'swap-cancel',
        pair: 'USDC/DOGE',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: Money.parse('10', Currency.usdc),
        wallet: 'savings',
        venue: PaperVenue.limit,
        pay: Currency.usdc,
        receive: Currency.doge,
      ),
    );
    await paper.ledger.cancelHold(
      requestId: 'cancel-hold',
      orderId: 'ord-cancel',
    );
    await paper.ledger.placeHold(
      requestId: 'swap-fill',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
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
      ),
    );
    await paper.ledger.fillHold(
      orderId: 'ord-fill',
      credit: Money.parse('40', Currency.doge),
      book: LedgerBook.savings,
    );

    final items = (await repo(paper).getItems()).getRight().toNullable()!;
    final canceled = items.firstWhere((item) => item.id == 'ord-cancel');
    final filled = items.firstWhere((item) => item.id == 'ord-fill');
    expect(canceled.kind, InboxItemKind.canceled);
    expect(canceled.title, 'Canceled USDC to DOGE swap');
    expect(canceled.dateLabel, 'Today');
    expect(filled.kind, InboxItemKind.swap);
    expect(filled.title, 'Swapped USDC to DOGE');
    expect(filled.dateLabel, 'Today');
  });
}
