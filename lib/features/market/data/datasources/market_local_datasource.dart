import 'package:decimal/decimal.dart';

import '../../../../core/market/market_symbols.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/order_book.dart';

final class MarketLocalDataSource {
  const MarketLocalDataSource();

  static final _bookUpdatedAt = DateTime.utc(2026, 1, 1);

  String nameFor(Currency currency) {
    return switch (currency.code) {
      'BTC' => 'Bitcoin',
      'ETH' => 'Ethereum',
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

  /// Deterministic depth for tests and offline. Always [QuoteFreshness.stale].
  OrderBook? bookFor(
    Currency currency, {
    int depth = orderBookDefaultDepth,
  }) {
    if (binanceSymbolFor(currency) == null) {
      return null;
    }
    final seed = _bookSeed(currency);
    if (seed == null) {
      return null;
    }
    final mid = Decimal.parse(seed.mid);
    final step = Decimal.parse(seed.step);
    final baseSize = Decimal.parse(seed.size);
    final bids = <OrderBookLevel>[];
    final asks = <OrderBookLevel>[];
    for (var i = 1; i <= orderBookMaxDepth; i++) {
      final offset = step * Decimal.fromInt(i);
      final size = Money.fromDecimal(
        baseSize * Decimal.fromInt(orderBookMaxDepth + 1 - i),
        currency,
      );
      bids.add(
        OrderBookLevel(
          side: OrderBookSide.bid,
          price: Money.fromDecimal(mid - offset, Currency.usdt),
          size: size,
        ),
      );
      asks.add(
        OrderBookLevel(
          side: OrderBookSide.ask,
          price: Money.fromDecimal(mid + offset, Currency.usdt),
          size: size,
        ),
      );
    }
    return OrderBook.normalized(
      currency: currency,
      quote: Currency.usdt,
      bids: bids,
      asks: asks,
      freshness: QuoteFreshness.stale,
      updatedAt: _bookUpdatedAt,
      depth: depth,
    );
  }

  ({String mid, String step, String size})? _bookSeed(Currency currency) {
    return switch (currency.code) {
      'BTC' => (mid: '78899.13', step: '1.00', size: '0.01'),
      'ETH' => (mid: '2466.03', step: '0.10', size: '0.10'),
      'DOGE' => (mid: '0.18', step: '0.0001', size: '100'),
      'SOL' => (mid: '148.20', step: '0.05', size: '1'),
      'XRP' => (mid: '1.39', step: '0.001', size: '10'),
      'PEPE' => (mid: '0.00001', step: '0.0000001', size: '1000000'),
      'BONK' => (mid: '0.00002', step: '0.0000001', size: '1000000'),
      'USDC' => (mid: '1.00', step: '0.0001', size: '100'),
      'EURx' => (mid: '1.08', step: '0.0001', size: '100'),
      _ => null,
    };
  }
}
