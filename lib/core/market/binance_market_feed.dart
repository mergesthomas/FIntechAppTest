import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';

import '../clock/app_clock.dart';
import '../config/flavor_config.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'binance_ticker.dart';
import 'market_feed.dart';
import 'market_quote.dart';
import 'market_symbols.dart';
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
