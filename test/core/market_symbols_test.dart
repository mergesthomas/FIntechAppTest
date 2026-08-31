import 'package:fintech_app_test/core/market/market_symbols.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PEPE and BONK map to listed Binance USDT pairs', () {
    expect(binanceSymbolFor(Currency.pepe), 'PEPEUSDT');
    expect(binanceSymbolFor(Currency.bonk), 'BONKUSDT');
    expect(binanceTickerSymbols, containsAll(['PEPEUSDT', 'BONKUSDT']));
    expect(binanceTickerSymbols, isNot(contains('1000PEPEUSDT')));
    expect(binanceTickerSymbols, isNot(contains('NEXOUSDT')));
  });
}
