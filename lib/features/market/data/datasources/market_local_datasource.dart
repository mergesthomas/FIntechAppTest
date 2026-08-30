import '../../../../core/money/currency.dart';

final class MarketLocalDataSource {
  const MarketLocalDataSource();

  String nameFor(Currency currency) {
    return switch (currency.code) {
      'BTC' => 'Bitcoin',
      'ETH' => 'Ethereum',
      'NEXO' => 'NEXO',
      'DOGE' => 'Dogecoin',
      'SOL' => 'Solana',
      'XRP' => 'XRP',
      'PEPE' => 'Pepe',
      'BONK' => 'Bonk',
      'USDC' => 'USD Coin',
      'USDT' => 'Tether',
      'EURx' => 'EURx',
      'USD' => 'US Dollar',
      _ => currency.code,
    };
  }
}
