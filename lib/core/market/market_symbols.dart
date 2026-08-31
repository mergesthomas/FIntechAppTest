import '../money/currency.dart';

/// Binance public symbols. EURx is paper-mapped to EURUSDT.
String? binanceSymbolFor(Currency currency) {
  return switch (currency.code) {
    'BTC' => 'BTCUSDT',
    'ETH' => 'ETHUSDT',
    'DOGE' => 'DOGEUSDT',
    'SOL' => 'SOLUSDT',
    'XRP' => 'XRPUSDT',
    'PEPE' => 'PEPEUSDT',
    'BONK' => 'BONKUSDT',
    'USDC' => 'USDCUSDT',
    'EURx' => 'EURUSDT',
    _ => null,
  };
}

Currency? currencyForBinanceSymbol(String symbol) {
  return switch (symbol) {
    'BTCUSDT' => Currency.btc,
    'ETHUSDT' => Currency.eth,
    'DOGEUSDT' => Currency.doge,
    'SOLUSDT' => Currency.sol,
    'XRPUSDT' => Currency.xrp,
    'PEPEUSDT' => Currency.pepe,
    'BONKUSDT' => Currency.bonk,
    'USDCUSDT' => Currency.usdc,
    'EURUSDT' => Currency.eurx,
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
  'DOGEUSDT',
  'SOLUSDT',
  'XRPUSDT',
  'PEPEUSDT',
  'BONKUSDT',
  'USDCUSDT',
  'EURUSDT',
];

const binanceChartCurrencies = [
  Currency.btc,
  Currency.eth,
  Currency.doge,
  Currency.sol,
  Currency.xrp,
  Currency.pepe,
  Currency.bonk,
];
