import 'dart:async';

import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/config/flavor_config.dart';
import 'package:fintech_app_test/core/market/binance_market_feed.dart';
import 'package:fintech_app_test/core/market/live_market_socket.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeSocket implements LiveMarketSocket {
  final _controller = StreamController<Object?>.broadcast();

  @override
  Stream<Object?> get messages => _controller.stream;

  void add(String event) => _controller.add(event);

  void finish() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

void main() {
  test('socket drop keeps cache stale then a payload is live', () async {
    final sockets = <_FakeSocket>[_FakeSocket(), _FakeSocket()];
    var opens = 0;
    final feed = BinanceMarketFeed(
      flavor: FlavorConfig.dev,
      clock: MutableClock(),
      snapshotOnConnect: false,
      reconnectInitial: Duration.zero,
      openSocket: (uri) async => sockets[opens++],
    );

    await feed.connect();
    expect(feed.connection, QuoteFreshness.disconnected);

    sockets[0].add(
      '{"stream":"btcusdt@ticker","data":{"s":"BTCUSDT","c":"78899.13","P":"1.54"}}',
    );
    await Future<void>.delayed(Duration.zero);
    expect(feed.connection, QuoteFreshness.live);
    expect(feed.quoteFor(Currency.btc)?.freshness, QuoteFreshness.live);

    sockets[0].finish();
    await Future<void>.delayed(Duration.zero);
    expect(feed.connection, QuoteFreshness.stale);
    expect(feed.quoteFor(Currency.btc)?.freshness, QuoteFreshness.stale);

    await Future<void>.delayed(Duration.zero);
    expect(opens, 2);
    sockets[1].add(
      '{"stream":"btcusdt@ticker","data":{"s":"BTCUSDT","c":"79000.00","P":"1.60"}}',
    );
    await Future<void>.delayed(Duration.zero);
    expect(feed.connection, QuoteFreshness.live);
    expect(feed.quoteFor(Currency.btc)?.price.amount.toString(), '79000');

    feed.dispose();
  });

  test('depth payload updates the book as live', () async {
    final socket = _FakeSocket();
    final feed = BinanceMarketFeed(
      flavor: FlavorConfig.dev,
      clock: MutableClock(),
      snapshotOnConnect: false,
      openSocket: (uri) async => socket,
    );
    await feed.connect();
    socket.add(
      '{"stream":"btcusdt@depth20@100ms","data":{"lastUpdateId":1,"bids":[["78898.13","0.2"]],"asks":[["78900.13","0.1"]]}}',
    );
    await Future<void>.delayed(Duration.zero);
    final book = feed.depthFor(Currency.btc);
    expect(book?.freshness, QuoteFreshness.live);
    expect(book?.bids.first.price.amount.toString(), '78898.13');
    feed.dispose();
  });
}
