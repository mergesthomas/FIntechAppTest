import '../money/currency.dart';
import '../money/money.dart';
import 'candle_interval.dart';
import 'candle_series.dart';
import 'depth_book.dart';
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
  CandleSeries candlesFor(
    Currency currency, [
    CandleInterval interval = CandleInterval.m15,
  ]);
  Future<CandleSeries> refreshCandles(
    Currency currency,
    CandleInterval interval,
  );
  DepthBook? depthFor(Currency currency);
  Stream<DepthBook> get depths;
  Future<DepthBook?> refreshDepth(Currency currency);
  void dispose();
}
