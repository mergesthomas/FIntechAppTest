import '../money/currency.dart';
import '../money/money.dart';
import 'market_quote.dart';
import 'quote_freshness.dart';

abstract class MarketFeed {
  QuoteFreshness get connection;
  Stream<MarketQuote> get quotes;
  MarketQuote? quoteFor(Currency currency);
  Money? usdPrice(Currency currency);
  void dispose();
}
