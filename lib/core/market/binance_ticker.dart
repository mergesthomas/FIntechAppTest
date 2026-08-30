import 'package:decimal/decimal.dart';

import '../clock/app_clock.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'market_quote.dart';
import 'quote_freshness.dart';

/// Parses Binance 24h ticker JSON. Prices stay strings → [Money].
MarketQuote? parseBinanceTicker(
  Map<String, dynamic> json, {
  required AppClock clock,
  QuoteFreshness freshness = QuoteFreshness.live,
}) {
  final symbol = json['symbol'] as String? ?? '';
  final last = json['lastPrice'] as String? ?? json['c'] as String?;
  final change = json['priceChangePercent'] as String? ?? json['P'] as String?;
  if (symbol.isEmpty || last == null || last.isEmpty) {
    return null;
  }
  var changeRatio = Decimal.zero;
  if (change != null && change.isNotEmpty) {
    changeRatio = (Decimal.parse(change) / Decimal.fromInt(100)).toDecimal(
      scaleOnInfinitePrecision: 8,
    );
  }
  return MarketQuote(
    symbol: symbol,
    price: Money.parse(last, Currency.usdt),
    change24h: changeRatio,
    freshness: freshness,
    updatedAt: clock.now(),
  );
}
