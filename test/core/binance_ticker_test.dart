import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/market/binance_ticker.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Binance lastPrice strings without double', () {
    final quote = parseBinanceTicker(
      {
        'symbol': 'BTCUSDT',
        'lastPrice': '78899.13',
        'priceChangePercent': '1.54',
      },
      clock: MutableClock(),
    );
    expect(quote?.symbol, 'BTCUSDT');
    expect(quote?.price.amount.toString(), '78899.13');
    expect(quote?.freshness, QuoteFreshness.live);
  });
}
