import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/market/binance_klines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Binance kline close strings without double', () {
    final closes = parseBinanceKlineCloses([
      [1, '1', '1', '1', '100.50', '1'],
      [2, '1', '1', '1', '101.25', '1'],
    ]);
    expect(closes, [Decimal.parse('100.50'), Decimal.parse('101.25')]);
  });

  test('parses Binance kline OHLC strings without double', () {
    final candles = parseBinanceKlines([
      [
        DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
        '100.00',
        '110.00',
        '90.00',
        '105.50',
        '12.5',
      ],
    ]);
    expect(candles, hasLength(1));
    expect(candles.first.open, Decimal.parse('100.00'));
    expect(candles.first.high, Decimal.parse('110.00'));
    expect(candles.first.low, Decimal.parse('90.00'));
    expect(candles.first.close, Decimal.parse('105.50'));
    expect(candles.first.volume, Decimal.parse('12.5'));
  });
}
