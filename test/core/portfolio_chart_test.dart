import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/ledger/ledger_lot.dart';
import 'package:fintech_app_test/core/ledger/portfolio_chart.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ALL window starts at first activity, 1Y is last 365 days', () {
    final now = DateTime.utc(2026, 8, 31);
    final first = DateTime.utc(2025, 2, 28);
    expect(
      chartWindowStart(
        period: ChartPeriod.all,
        end: now,
        firstActivity: first,
      ),
      first,
    );
    expect(
      chartWindowStart(period: ChartPeriod.oneYear, end: now),
      DateTime.utc(2025, 8, 31),
    );
  });

  test('portfolio value jumps when a buy lot enters the window', () {
    final start = DateTime.utc(2025, 1, 1);
    final buy = DateTime.utc(2025, 6, 1);
    final end = DateTime.utc(2026, 1, 1);
    final lots = [
      LedgerLot(
        currency: Currency.usdc,
        quantity: Decimal.parse('10000'),
        at: buy,
      ),
    ];
    final balances = [Money.parse('10000', Currency.usdc)];
    final times = [
      start,
      buy.subtract(const Duration(seconds: 1)),
      buy,
      end,
    ];
    final chart = buildPortfolioChart(
      lots: lots,
      balances: balances,
      times: times,
      usdRateAt: (currency, at) => Decimal.one,
    );

    expect(chart.first.value.amount, Decimal.zero);
    expect(chart[1].value.amount, Decimal.zero);
    expect(chart[2].value.amount, Decimal.parse('10000'));
    expect(chart.last.value.amount, Decimal.parse('10000'));
  });

  test('sample times include buy events and a pre-start point for ALL', () {
    final start = DateTime.utc(2025, 1, 1);
    final buy = DateTime.utc(2025, 6, 1);
    final end = DateTime.utc(2026, 1, 1);
    final times = portfolioSampleTimes(
      start: start,
      end: end,
      count: 4,
      events: [buy],
      includePreStart: true,
    );

    expect(times.first.isBefore(start), isTrue);
    expect(times, contains(buy));
    expect(times.last, end);
  });
}
