import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';

import '../clock/app_clock.dart';
import '../config/flavor_config.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'binance_klines.dart';
import 'binance_ticker.dart';
import 'market_feed.dart';
import 'market_quote.dart';
import 'market_symbols.dart';
import 'price_series.dart';
import 'quote_freshness.dart';

final class BinanceMarketFeed implements MarketFeed {
  BinanceMarketFeed({
    required FlavorConfig flavor,
    required AppClock clock,
    this.staleAfter = const Duration(seconds: 15),
  })  : _flavor = flavor,
        _clock = clock;

  final FlavorConfig _flavor;
  final AppClock _clock;
  final Duration staleAfter;
  final Map<String, MarketQuote> _quotes = {};
  final Map<String, PriceSeries> _series = {};
  final _controller = StreamController<MarketQuote>.broadcast();
  QuoteFreshness _connection = QuoteFreshness.disconnected;
  HttpClient? _http;
  WebSocket? _socket;
  Timer? _watchdog;
  DateTime? _lastTick;
  var _closed = false;

  @override
  QuoteFreshness get connection {
    _decay();
    return _connection;
  }

  @override
  Stream<MarketQuote> get quotes => _controller.stream;

  Future<void> connect() async {
    if (_closed) {
      return;
    }
    await _snapshot();
    await _listen();
  }

  Future<void> _snapshot() async {
    try {
      _http ??= HttpClient();
      final symbols = jsonEncode(binanceTickerSymbols);
      final uri = Uri.parse(
        '${_flavor.marketRestUrl}/api/v3/ticker/24hr?symbols=$symbols',
      );
      final request = await _http!.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        _connection = QuoteFreshness.disconnected;
        return;
      }
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        _connection = QuoteFreshness.disconnected;
        return;
      }
      for (final row in decoded) {
        if (row is Map<String, dynamic>) {
          final quote = parseBinanceTicker(
            row,
            clock: _clock,
            freshness: QuoteFreshness.live,
          );
          if (quote != null) {
            _put(quote);
          }
        }
      }
      _connection = QuoteFreshness.live;
      _lastTick = _clock.now();
      unawaited(refreshSeries(Currency.btc, ChartPeriod.oneDay));
      unawaited(refreshSeries(Currency.eth, ChartPeriod.oneDay));
      unawaited(refreshSeries(Currency.nexo, ChartPeriod.oneDay));
    } on Object {
      _connection = QuoteFreshness.disconnected;
    }
  }

  Future<void> _listen() async {
    try {
      final streams = binanceTickerSymbols
          .map((s) => '${s.toLowerCase()}@ticker')
          .join('/');
      final uri = Uri.parse('${_flavor.marketWsUrl}/stream?streams=$streams');
      _socket = await WebSocket.connect(uri.toString());
      _connection = QuoteFreshness.live;
      _watchdog?.cancel();
      _watchdog = Timer.periodic(const Duration(seconds: 5), (_) => _decay());
      _socket!.listen(
        (event) {
          if (event is! String) {
            return;
          }
          final decoded = jsonDecode(event);
          if (decoded is! Map<String, dynamic>) {
            return;
          }
          final data = decoded['data'];
          if (data is! Map<String, dynamic>) {
            return;
          }
          data['symbol'] = (data['s'] as String?) ?? data['symbol'];
          final quote = parseBinanceTicker(
            data,
            clock: _clock,
            freshness: QuoteFreshness.live,
          );
          if (quote != null) {
            _lastTick = _clock.now();
            _connection = QuoteFreshness.live;
            _put(quote);
          }
        },
        onError: (_) => _connection = QuoteFreshness.disconnected,
        onDone: () => _connection = QuoteFreshness.disconnected,
        cancelOnError: false,
      );
    } on Object {
      _connection = _quotes.isEmpty
          ? QuoteFreshness.disconnected
          : QuoteFreshness.stale;
    }
  }

  void _put(MarketQuote quote) {
    _quotes[quote.symbol] = quote;
    if (!_controller.isClosed) {
      _controller.add(quote);
    }
  }

  void _decay() {
    final last = _lastTick;
    if (last == null) {
      return;
    }
    if (_clock.now().difference(last) > staleAfter) {
      _connection = _connection == QuoteFreshness.disconnected
          ? QuoteFreshness.disconnected
          : QuoteFreshness.stale;
      for (final entry in _quotes.entries) {
        _quotes[entry.key] = entry.value.copyWith(freshness: _connection);
      }
    }
  }

  @override
  MarketQuote? quoteFor(Currency currency) {
    _decay();
    if (isUsdPeg(currency)) {
      return MarketQuote(
        symbol: 'USD',
        price: Money.parse('1', Currency.usdt),
        change24h: Decimal.zero,
        freshness: _connection == QuoteFreshness.disconnected
            ? QuoteFreshness.disconnected
            : _connection,
        updatedAt: _clock.now(),
      );
    }
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return null;
    }
    final quote = _quotes[symbol];
    if (quote == null) {
      return null;
    }
    return quote.copyWith(freshness: _connection);
  }

  String _seriesKey(Currency currency, ChartPeriod period) {
    return '${currency.code}:${period.name}';
  }

  @override
  PriceSeries seriesFor(
    Currency currency, [
    ChartPeriod period = ChartPeriod.oneDay,
  ]) {
    _decay();
    final cached = _series[_seriesKey(currency, period)];
    if (cached != null) {
      return cached.copyWith(freshness: _connection);
    }
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
    if (_closed) {
      return seriesFor(currency, period);
    }
    if (isUsdPeg(currency)) {
      final peg = PriceSeries(
        period: period,
        closes: List.filled(24, Decimal.one),
        freshness: connection,
      );
      _series[_seriesKey(currency, period)] = peg;
      return peg;
    }
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return seriesFor(currency, period);
    }
    try {
      _http ??= HttpClient();
      final interval = switch (period) {
        ChartPeriod.oneDay => '1h',
        ChartPeriod.oneWeek => '4h',
        ChartPeriod.oneMonth => '1d',
        ChartPeriod.oneYear => '1w',
      };
      final limit = switch (period) {
        ChartPeriod.oneDay => 24,
        ChartPeriod.oneWeek => 42,
        ChartPeriod.oneMonth => 30,
        ChartPeriod.oneYear => 52,
      };
      final uri = Uri.parse(
        '${_flavor.marketRestUrl}/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit',
      );
      final request = await _http!.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return seriesFor(currency, period);
      }
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return seriesFor(currency, period);
      }
      var closes = parseBinanceKlineCloses(decoded);
      if (closes.length < 2) {
        return seriesFor(currency, period);
      }
      if (currency.code == 'PEPE') {
        closes = [
          for (final close in closes)
            (close / Decimal.fromInt(1000)).toDecimal(
              scaleOnInfinitePrecision: 18,
            ),
        ];
      }
      final series = PriceSeries(
        period: period,
        closes: closes,
        freshness: _connection,
      );
      _series[_seriesKey(currency, period)] = series;
      return series;
    } on Object {
      return seriesFor(currency, period);
    }
  }

  @override
  Money? usdPrice(Currency currency) {
    final quote = quoteFor(currency);
    if (quote == null) {
      return null;
    }
    var amount = quote.price.amount;
    if (currency.code == 'PEPE') {
      amount = (amount / Decimal.fromInt(1000)).toDecimal(
        scaleOnInfinitePrecision: 18,
      );
    }
    return Money.fromDecimal(amount, Currency.usd);
  }

  @override
  void dispose() {
    _closed = true;
    _watchdog?.cancel();
    _socket?.close();
    _http?.close(force: true);
    _controller.close();
  }
}
