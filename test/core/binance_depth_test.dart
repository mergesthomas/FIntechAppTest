import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/market/binance_depth.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses REST depth strings without double', () {
    final book = parseBinanceDepth(
      {
        'lastUpdateId': 1,
        'bids': [
          ['78898.13', '0.20'],
          ['78897.13', '0.10'],
        ],
        'asks': [
          ['78900.13', '0.15'],
        ],
      },
      clock: MutableClock(),
      symbol: 'BTCUSDT',
    );
    expect(book?.symbol, 'BTCUSDT');
    expect(book?.freshness, QuoteFreshness.live);
    expect(book?.bids.first.price.amount.toString(), '78898.13');
    expect(book?.bids.first.quantity.toString(), '0.2');
    expect(book?.asks.first.price.amount.toString(), '78900.13');
  });

  test('parses diff-style b/a keys and rejects junk rows', () {
    final book = parseBinanceDepth(
      {
        's': 'ETHUSDT',
        'b': [
          ['2466.03', '1.5'],
          [2466, 2],
          ['bad', '1'],
        ],
        'a': [
          ['2466.13', '0.4'],
        ],
      },
      clock: MutableClock(),
    );
    expect(book?.symbol, 'ETHUSDT');
    expect(book?.bids, hasLength(1));
    expect(book?.bids.single.price.amount.toString(), '2466.03');
  });

  test('returns null when no usable levels', () {
    expect(
      parseBinanceDepth(
        {'bids': [], 'asks': []},
        clock: MutableClock(),
        symbol: 'BTCUSDT',
      ),
      isNull,
    );
  });

  test('reads the symbol from a depth stream name', () {
    expect(
      symbolFromDepthStream('btcusdt@depth20@100ms'),
      'BTCUSDT',
    );
  });
}
