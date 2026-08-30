import '../money/currency.dart';

/// Binance public symbols. EURx is paper-mapped to EURUSDT.
String? binanceSymbolFor(Currency currency) {
  return switch (currency.code) {
    'BTC' => 'BTCUSDT',
    'ETH' => 'ETHUSDT',
    'NEXO' => 'NEXOUSDT',
    'DOGE' => 'DOGEUSDT',
    'SOL' => 'SOLUSDT',
    'XRP' => 'XRPUSDT',
    'PEPE' => '1000PEPEUSDT',
    'BONK' => 'BONKUSDT',
    'USDC' => 'USDCUSDT',
    'EURx' => 'EURUSDT',
    _ => null,
  };
}

bool isUsdPeg(Currency currency) {
  return switch (currency.code) {
    'USD' || 'USDT' || 'USDx' || 'xUSD' => true,
    _ => false,
  };
}

const binanceTickerSymbols = [
  'BTCUSDT',
  'ETHUSDT',
  'NEXOUSDT',
  'DOGEUSDT',
  'SOLUSDT',
  'XRPUSDT',
  '1000PEPEUSDT',
  'BONKUSDT',
  'USDCUSDT',
  'EURUSDT',
];
