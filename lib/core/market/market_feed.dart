import '../money/currency.dart';
import '../money/money.dart';
import 'market_quote.dart';
import 'price_series.dart';
import 'quote_freshness.dart';

abstract class MarketFeed {
  QuoteFreshness get connection;
  Stream<MarketQuote> get quotes;
  MarketQuote? quoteFor(Currency currency);
  Money? usdPrice(Currency currency);
  PriceSeries seriesFor(
    Currency currency, [
    ChartPeriod period = ChartPeriod.oneDay,
  ]);
  Future<PriceSeries> refreshSeries(Currency currency, ChartPeriod period);
  void dispose();
}
