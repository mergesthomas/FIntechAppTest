import 'dart:async';

import 'package:decimal/decimal.dart';

import '../clock/app_clock.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'candle_interval.dart';
import 'candle_series.dart';
import 'market_feed.dart';
import 'market_quote.dart';
import 'market_symbols.dart';
import 'price_series.dart';
import 'quote_freshness.dart';

final class InMemoryMarketFeed implements MarketFeed {
  InMemoryMarketFeed({
    AppClock clock = const SystemClock(),
    QuoteFreshness connection = QuoteFreshness.stale,
  })  : _clock = clock,
        _connection = connection {
    _seed();
  }

  final AppClock _clock;
  QuoteFreshness _connection;
  final Map<String, MarketQuote> _quotes = {};
  final _controller = StreamController<MarketQuote>.broadcast();

  @override
  QuoteFreshness get connection => _connection;

  @override
  Stream<MarketQuote> get quotes => _controller.stream;

  void setConnection(QuoteFreshness value) {
    _connection = value;
    for (final entry in _quotes.entries) {
      _quotes[entry.key] = entry.value.copyWith(freshness: value);
    }
  }

  void put(MarketQuote quote) {
    _quotes[quote.symbol] = quote.copyWith(freshness: _connection);
    _controller.add(_quotes[quote.symbol]!);
  }

  void _seed() {
    void add(String symbol, String price, String change) {
      _quotes[symbol] = MarketQuote(
        symbol: symbol,
        price: Money.parse(price, Currency.usdt),
        change24h: Decimal.parse(change),
        freshness: _connection,
        updatedAt: _clock.now(),
      );
    }

    add('BTCUSDT', '78899.13', '0.0154');
    add('ETHUSDT', '2466.03', '0.0128');
    add('NEXOUSDT', '0.8639', '0.0499');
    add('DOGEUSDT', '0.18', '-0.0120');
    add('SOLUSDT', '148.20', '0.0210');
    add('XRPUSDT', '1.39', '0.0096');
    add('PEPEUSDT', '0.00001', '0.0320');
    add('BONKUSDT', '0.00002', '-0.0080');
    add('USDCUSDT', '1.00', '0.0000');
    add('EURUSDT', '1.08', '0.0010');
  }

  @override
  MarketQuote? quoteFor(Currency currency) {
    if (isUsdPeg(currency)) {
      return MarketQuote(
        symbol: 'USD',
        price: Money.parse('1', Currency.usdt),
        change24h: Decimal.zero,
        freshness: _connection,
        updatedAt: _clock.now(),
      );
    }
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return null;
    }
    return _quotes[symbol];
  }

  @override
  PriceSeries seriesFor(
    Currency currency, [
    ChartPeriod period = ChartPeriod.oneDay,
  ]) {
    final last = usdPrice(currency)?.amount ?? Decimal.one;
    return PriceSeries(
      period: period,
      closes: syntheticCloses(last: last, period: period),
      freshness: _connection,
    );
  }

  @override
  Future<PriceSeries> refreshSeries(
    Currency currency,
    ChartPeriod period,
  ) async {
    return seriesFor(currency, period);
  }

  @override
  CandleSeries candlesFor(
    Currency currency, [
    CandleInterval interval = CandleInterval.m15,
  ]) {
    final last = usdPrice(currency)?.amount ?? Decimal.one;
    return syntheticCandleSeries(
      last: last,
      interval: interval,
      now: _clock.now(),
      freshness: _connection,
    );
  }

  @override
  Future<CandleSeries> refreshCandles(
    Currency currency,
    CandleInterval interval,
  ) async {
    return candlesFor(currency, interval);
  }

  @override
  Money? usdPrice(Currency currency) {
    final quote = quoteFor(currency);
    if (quote == null) {
      return null;
    }
    return Money.fromDecimal(quote.price.amount, Currency.usd);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
