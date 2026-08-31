import '../../../core/ledger/portfolio_chart.dart';
import '../../../core/market/market_feed.dart';
import '../../../core/market/market_symbols.dart';
import '../../../core/market/price_series.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';

const inboxPriceLookback = Duration(days: 365 * 3);

/// USD per one unit of [asset] on [at], from the same series as the portfolio.
Money? inboxUnitPriceUsd({
  required MarketFeed feed,
  required Currency asset,
  required DateTime at,
  required DateTime now,
}) {
  if (isUsdPeg(asset)) {
    return Money.parse('1', Currency.usd);
  }
  final live = feed.usdPrice(asset);
  if (live == null) {
    return null;
  }
  final end = now.toUtc();
  final start = end.subtract(inboxPriceLookback);
  final series = feed.seriesFor(asset, ChartPeriod.all);
  return Money.fromDecimal(
    seriesRateAt(
      closes: series.closes,
      start: start,
      end: end,
      at: at,
      fallback: live.amount,
    ),
    Currency.usd,
  );
}
