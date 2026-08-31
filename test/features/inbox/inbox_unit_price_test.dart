import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/ledger/portfolio_chart.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/inbox/data/inbox_unit_price.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clock = MutableClock(DateTime.utc(2026, 8, 31));

  test('usd pegs are one dollar on every day', () {
    final feed = InMemoryMarketFeed(clock: clock);
    expect(
      inboxUnitPriceUsd(
        feed: feed,
        asset: Currency.usd,
        at: DateTime.utc(2025, 3, 1),
        now: clock.now(),
      ),
      Money.parse('1', Currency.usd),
    );
  });

  test('crypto uses the series close on that day, not the live last', () {
    final feed = InMemoryMarketFeed(clock: clock);
    final now = clock.now().toUtc();
    final at = now.subtract(const Duration(days: 487));
    final live = feed.usdPrice(Currency.btc)!;
    final series = feed.seriesFor(Currency.btc, ChartPeriod.all);
    final expected = seriesRateAt(
      closes: series.closes,
      start: now.subtract(inboxPriceLookback),
      end: now,
      at: at,
      fallback: live.amount,
    );

    expect(
      inboxUnitPriceUsd(
        feed: feed,
        asset: Currency.btc,
        at: at,
        now: now,
      ),
      Money.fromDecimal(expected, Currency.usd),
    );
    expect(
      inboxUnitPriceUsd(
        feed: feed,
        asset: Currency.btc,
        at: at,
        now: now,
      ),
      isNot(live),
    );
  });
}
