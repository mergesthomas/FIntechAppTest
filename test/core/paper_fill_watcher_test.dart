import 'package:fintech_app_test/core/ledger/paper_fill_watcher.dart';
import 'package:fintech_app_test/core/ledger/paper_ledger.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/market/market_quote.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/market/quote_math.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/paper_harness.dart';

void main() {
  test('limit order fills when live from-per-to reaches the limit', () async {
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final watcher = PaperFillWatcher(feed: paper.feed, ledger: paper.ledger);
    addTearDown(watcher.dispose);

    final live = convertWithFeed(
      feed: paper.feed,
      from: Money.parse('1', Currency.doge),
      to: Currency.usdc,
    ).getRight().toNullable()!;
    final limit = Money.fromDecimal(
      live.to.amount - Decimal.parse('0.01'),
      Currency.usdc,
    );

    await paper.ledger.placeHold(
      requestId: 'swap-limit-1',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
        id: 'ord-limit-1',
        requestId: 'swap-limit-1',
        pair: 'USDC/DOGE',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: Money.parse('10', Currency.usdc),
        wallet: 'savings',
        venue: PaperVenue.limit,
        pay: Currency.usdc,
        receive: Currency.doge,
        limitPrice: limit,
      ),
    );

    await watcher.evaluate();
    expect(paper.store.all.first.status, PaperOrderStatus.open);

    paper.feed.put(
      MarketQuote(
        symbol: 'DOGEUSDT',
        price: Money.parse('0.01', Currency.usdt),
        change24h: Decimal.zero,
        freshness: QuoteFreshness.live,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await watcher.evaluate();

    expect(paper.store.all.first.status, PaperOrderStatus.filled);
    expect(
      paper.ledger.balance(LedgerBook.savings, Currency.doge).isPositive,
      isTrue,
    );
  });

  test('does not fill when the feed is stale', () async {
    final paper = PaperHarness(freshness: QuoteFreshness.stale);
    final watcher = PaperFillWatcher(feed: paper.feed, ledger: paper.ledger);
    addTearDown(watcher.dispose);

    await paper.ledger.placeHold(
      requestId: 'swap-limit-stale',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
        id: 'ord-limit-stale',
        requestId: 'swap-limit-stale',
        pair: 'USDC/DOGE',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: Money.parse('10', Currency.usdc),
        wallet: 'savings',
        venue: PaperVenue.limit,
        pay: Currency.usdc,
        receive: Currency.doge,
        limitPrice: Money.parse('9', Currency.usdc),
      ),
    );
    await watcher.evaluate();
    expect(paper.store.all.first.status, PaperOrderStatus.open);
  });
}
