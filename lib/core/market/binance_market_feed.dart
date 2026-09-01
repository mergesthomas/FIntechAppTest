import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';

import '../clock/app_clock.dart';
import '../config/flavor_config.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'binance_depth.dart';
import 'binance_klines.dart';
import 'binance_ticker.dart';
import 'candle_interval.dart';
import 'candle_series.dart';
import 'depth_book.dart';
import 'live_market_socket.dart';
import 'market_feed.dart';
import 'market_quote.dart';
import 'market_symbols.dart';
import 'price_series.dart';
import 'quote_freshness.dart';
import 'reconnect_backoff.dart';

final class _IoMarketSocket implements LiveMarketSocket {
  _IoMarketSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<Object?> get messages => _socket;

  @override
  Future<void> close() => _socket.close();
}

final class BinanceMarketFeed implements MarketFeed {
  BinanceMarketFeed({
    required FlavorConfig flavor,
    required AppClock clock,
    this.staleAfter = const Duration(seconds: 15),
    this.snapshotOnConnect = true,
    OpenLiveMarketSocket? openSocket,
    Duration reconnectInitial = const Duration(seconds: 1),
    Duration reconnectMax = const Duration(seconds: 30),
  }) : _flavor = flavor,
       _clock = clock,
       _openSocket = openSocket ??
           ((uri) async => _IoMarketSocket(await WebSocket.connect(uri.toString()))),
       _backoff = ReconnectBackoff(
         initial: reconnectInitial,
         max: reconnectMax,
       );

  final FlavorConfig _flavor;
  final AppClock _clock;
  final Duration staleAfter;
  final bool snapshotOnConnect;
  final OpenLiveMarketSocket _openSocket;
  final ReconnectBackoff _backoff;
  final Map<String, MarketQuote> _quotes = {};
  final Map<String, DepthBook> _depths = {};
  final Map<String, PriceSeries> _series = {};
  final Map<String, Future<PriceSeries>> _inflight = {};
  final Map<String, CandleSeries> _candles = {};
  final Map<String, Future<CandleSeries>> _candleInflight = {};
  final _controller = StreamController<MarketQuote>.broadcast();
  final _depthController = StreamController<DepthBook>.broadcast();
  QuoteFreshness _connection = QuoteFreshness.disconnected;
  HttpClient? _http;
  LiveMarketSocket? _socket;
  StreamSubscription<Object?>? _socketSub;
  Timer? _watchdog;
  Timer? _reconnectTimer;
  DateTime? _lastTick;
  var _closed = false;
  var _listening = false;

  @override
  QuoteFreshness get connection {
    _decay();
    return _connection;
  }

  @override
  Stream<MarketQuote> get quotes => _controller.stream;

  @override
  Stream<DepthBook> get depths => _depthController.stream;

  Future<void> connect() async {
    if (_closed) {
      return;
    }
    if (snapshotOnConnect) {
      await _snapshot();
      await _snapshotDepths();
    }
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
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
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
      unawaited(
        Future.wait([
          for (final currency in binanceChartCurrencies)
            refreshSeries(currency, ChartPeriod.oneDay),
        ]),
      );
    } on Object {
      _connection = QuoteFreshness.disconnected;
    }
  }

  Future<void> _snapshotDepths() async {
    try {
      _http ??= HttpClient();
      for (final symbol in binanceTickerSymbols) {
        if (_closed) {
          return;
        }
        final uri = Uri.parse(
          '${_flavor.marketRestUrl}/api/v3/depth?symbol=$symbol&limit=20',
        );
        final request = await _http!.getUrl(uri);
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        if (response.statusCode != 200) {
          continue;
        }
        final body = await utf8.decodeStream(response);
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        final book = parseBinanceDepth(
          decoded,
          clock: _clock,
          symbol: symbol,
          freshness: QuoteFreshness.live,
        );
        if (book != null) {
          _putDepth(book);
        }
      }
    } on Object {
      // Keep last cache. Connection freshness comes from the ticker snapshot.
    }
  }

  Future<void> _listen() async {
    if (_closed || _listening) {
      return;
    }
    _listening = true;
    await _detachSocket();
    try {
      final tickers = binanceTickerSymbols.map(
        (s) => '${s.toLowerCase()}@ticker',
      );
      final books = binanceTickerSymbols.map(
        (s) => '${s.toLowerCase()}@depth20@100ms',
      );
      final streams = [...tickers, ...books].join('/');
      final uri = Uri.parse('${_flavor.marketWsUrl}/stream?streams=$streams');
      _socket = await _openSocket(uri);
      if (_closed) {
        _listening = false;
        await _detachSocket();
        return;
      }
      _watchdog?.cancel();
      _watchdog = Timer.periodic(const Duration(seconds: 5), (_) => _decay());
      _socketSub = _socket!.messages.listen(
        _onMessage,
        onError: (_) => _onLost(),
        onDone: _onLost,
        cancelOnError: false,
      );
    } on Object {
      _listening = false;
      _onLost();
    }
  }

  void _onMessage(Object? event) {
    if (event is! String) {
      return;
    }
    final decoded = jsonDecode(event);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    final stream = decoded['stream'] as String? ?? '';
    final raw = decoded['data'];
    final data = raw is Map<String, dynamic> ? raw : decoded;
    final isDepth = stream.contains('@depth') ||
        data['bids'] is List ||
        data['asks'] is List ||
        data['b'] is List ||
        data['a'] is List;
    if (isDepth) {
      final symbol = symbolFromDepthStream(stream) ?? data['s'] as String?;
      final book = parseBinanceDepth(
        data,
        clock: _clock,
        symbol: symbol,
        freshness: QuoteFreshness.live,
      );
      if (book != null) {
        _noteLive();
        _putDepth(book);
      }
      return;
    }
    data['symbol'] = (data['s'] as String?) ?? data['symbol'];
    final quote = parseBinanceTicker(
      data,
      clock: _clock,
      freshness: QuoteFreshness.live,
    );
    if (quote != null) {
      _noteLive();
      _put(quote);
    }
  }

  void _noteLive() {
    _lastTick = _clock.now();
    _connection = QuoteFreshness.live;
    _backoff.reset();
  }

  void _onLost() {
    if (_closed) {
      return;
    }
    _listening = false;
    unawaited(_detachSocket());
    _markLost();
    _scheduleReconnect();
  }

  void _markLost() {
    if (_quotes.isEmpty && _depths.isEmpty) {
      _connection = QuoteFreshness.disconnected;
      return;
    }
    _connection = QuoteFreshness.stale;
    final quotes = _quotes.values.toList();
    for (final quote in quotes) {
      _put(quote.copyWith(freshness: QuoteFreshness.stale));
    }
    for (final entry in _depths.entries) {
      final stale = entry.value.copyWith(freshness: QuoteFreshness.stale);
      _depths[entry.key] = stale;
      if (!_depthController.isClosed) {
        _depthController.add(stale);
      }
    }
  }

  void _scheduleReconnect() {
    if (_closed || _reconnectTimer != null) {
      return;
    }
    final delay = _backoff.next();
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_closed) {
        return;
      }
      unawaited(_listen());
    });
  }

  Future<void> _detachSocket() async {
    await _socketSub?.cancel();
    _socketSub = null;
    try {
      await _socket?.close();
    } on Object {
      // Already closed.
    }
    _socket = null;
  }

  void _put(MarketQuote quote) {
    _quotes[quote.symbol] = quote;
    if (!_controller.isClosed) {
      _controller.add(quote);
    }
  }

  void _putDepth(DepthBook book) {
    _depths[book.symbol] = book;
    if (!_depthController.isClosed) {
      _depthController.add(book);
    }
  }

  void _decay() {
    final last = _lastTick;
    if (last == null) {
      return;
    }
    if (_clock.now().difference(last) > staleAfter) {
      _connection =
          _connection == QuoteFreshness.disconnected
              ? QuoteFreshness.disconnected
              : QuoteFreshness.stale;
      for (final entry in _quotes.entries) {
        _quotes[entry.key] = entry.value.copyWith(freshness: _connection);
      }
      for (final entry in _depths.entries) {
        _depths[entry.key] = entry.value.copyWith(freshness: _connection);
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
        freshness:
            _connection == QuoteFreshness.disconnected
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
    return _syntheticSeries(currency, period);
  }

  PriceSeries _syntheticSeries(Currency currency, ChartPeriod period) {
    final last = usdPrice(currency)?.amount ?? Decimal.one;
    return PriceSeries(
      period: period,
      closes: syntheticCloses(
        last: last,
        period: period,
        seedKey: currency.code,
        changeRatio: quoteFor(currency)?.change24h,
      ),
      freshness: QuoteFreshness.stale,
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
    final key = _seriesKey(currency, period);
    final cached = _series[key];
    if (cached != null) {
      return cached.copyWith(freshness: _connection);
    }
    final pending = _inflight[key];
    if (pending != null) {
      return pending;
    }
    final future = _fetchSeries(currency, period);
    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<PriceSeries> _fetchSeries(
    Currency currency,
    ChartPeriod period,
  ) async {
    if (isUsdPeg(currency)) {
      final peg = PriceSeries(
        period: period,
        closes: List.filled(syntheticPointCount(period), Decimal.one),
        freshness: connection,
      );
      _series[_seriesKey(currency, period)] = peg;
      return peg;
    }
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return _syntheticSeries(currency, period);
    }
    try {
      _http ??= HttpClient();
      final interval = switch (period) {
        ChartPeriod.oneDay => '1h',
        ChartPeriod.oneWeek => '4h',
        ChartPeriod.oneMonth => '1d',
        ChartPeriod.oneYear => '1w',
        ChartPeriod.all => '1w',
      };
      final limit = switch (period) {
        ChartPeriod.oneDay => 24,
        ChartPeriod.oneWeek => 42,
        ChartPeriod.oneMonth => 30,
        ChartPeriod.oneYear => 52,
        ChartPeriod.all => 104,
      };
      final uri = Uri.parse(
        '${_flavor.marketRestUrl}/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit',
      );
      final request = await _http!.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != 200) {
        return _syntheticSeries(currency, period);
      }
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return _syntheticSeries(currency, period);
      }
      final closes = parseBinanceKlineCloses(decoded);
      if (closes.length < 2) {
        return _syntheticSeries(currency, period);
      }
      final series = PriceSeries(
        period: period,
        closes: closes,
        freshness: _connection,
      );
      _series[_seriesKey(currency, period)] = series;
      return series;
    } on Object {
      return _syntheticSeries(currency, period);
    }
  }

  String _candleKey(Currency currency, CandleInterval interval) {
    return '${currency.code}:${interval.name}';
  }

  CandleSeries _syntheticCandles(Currency currency, CandleInterval interval) {
    final last = usdPrice(currency)?.amount ?? Decimal.one;
    return syntheticCandleSeries(
      last: last,
      interval: interval,
      now: _clock.now(),
      freshness: QuoteFreshness.stale,
    );
  }

  @override
  CandleSeries candlesFor(
    Currency currency, [
    CandleInterval interval = CandleInterval.m15,
  ]) {
    _decay();
    final cached = _candles[_candleKey(currency, interval)];
    if (cached != null) {
      return cached.copyWith(freshness: _connection);
    }
    return _syntheticCandles(currency, interval);
  }

  @override
  Future<CandleSeries> refreshCandles(
    Currency currency,
    CandleInterval interval,
  ) async {
    if (_closed) {
      return candlesFor(currency, interval);
    }
    final key = _candleKey(currency, interval);
    final pending = _candleInflight[key];
    if (pending != null) {
      return pending;
    }
    final future = _fetchCandles(currency, interval);
    _candleInflight[key] = future;
    try {
      return await future;
    } finally {
      _candleInflight.remove(key);
    }
  }

  Future<CandleSeries> _fetchCandles(
    Currency currency,
    CandleInterval interval,
  ) async {
    if (isUsdPeg(currency)) {
      final peg = syntheticCandleSeries(
        last: Decimal.one,
        interval: interval,
        now: _clock.now(),
        freshness: connection,
      );
      _candles[_candleKey(currency, interval)] = peg;
      return peg;
    }
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return _syntheticCandles(currency, interval);
    }
    try {
      _http ??= HttpClient();
      final uri = Uri.parse(
        '${_flavor.marketRestUrl}/api/v3/klines?symbol=$symbol&interval=${interval.binanceCode}&limit=${interval.requestLimit}',
      );
      final request = await _http!.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != 200) {
        return _cachedOrSynthetic(currency, interval);
      }
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return _cachedOrSynthetic(currency, interval);
      }
      final parsed = parseBinanceKlines(decoded);
      if (parsed.length < 2) {
        return _cachedOrSynthetic(currency, interval);
      }
      final series = CandleSeries(
        interval: interval,
        candles: parsed,
        freshness: _connection,
      );
      _candles[_candleKey(currency, interval)] = series;
      return series;
    } on Object {
      return _cachedOrSynthetic(currency, interval);
    }
  }

  CandleSeries _cachedOrSynthetic(Currency currency, CandleInterval interval) {
    final cached = _candles[_candleKey(currency, interval)];
    if (cached != null) {
      return cached.copyWith(
        freshness:
            _connection == QuoteFreshness.disconnected
                ? QuoteFreshness.disconnected
                : QuoteFreshness.stale,
      );
    }
    return _syntheticCandles(currency, interval);
  }

  @override
  DepthBook? depthFor(Currency currency) {
    _decay();
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return null;
    }
    final book = _depths[symbol];
    if (book == null) {
      return null;
    }
    return book.copyWith(freshness: _connection);
  }

  @override
  Future<DepthBook?> refreshDepth(Currency currency) async {
    _decay();
    final cached = depthFor(currency);
    if (cached != null) {
      return cached;
    }
    if (_closed || !snapshotOnConnect) {
      return null;
    }
    final symbol = binanceSymbolFor(currency);
    if (symbol == null) {
      return null;
    }
    try {
      _http ??= HttpClient();
      final uri = Uri.parse(
        '${_flavor.marketRestUrl}/api/v3/depth?symbol=$symbol&limit=20',
      );
      final request = await _http!.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final book = parseBinanceDepth(
        decoded,
        clock: _clock,
        symbol: symbol,
        freshness: _connection == QuoteFreshness.disconnected
            ? QuoteFreshness.stale
            : _connection,
      );
      if (book != null) {
        _putDepth(book);
      }
      return book;
    } on Object {
      return null;
    }
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
    _closed = true;
    _watchdog?.cancel();
    _reconnectTimer?.cancel();
    unawaited(_detachSocket());
    _http?.close(force: true);
    _controller.close();
    _depthController.close();
  }
}
