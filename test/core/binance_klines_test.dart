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
}
