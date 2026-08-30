import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../money/money.dart';
import 'quote_freshness.dart';

final class MarketQuote extends Equatable {
  const MarketQuote({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.freshness,
    required this.updatedAt,
  });

  final String symbol;
  final Money price;
  final Decimal change24h;
  final QuoteFreshness freshness;
  final DateTime updatedAt;

  MarketQuote copyWith({
    Money? price,
    Decimal? change24h,
    QuoteFreshness? freshness,
    DateTime? updatedAt,
  }) {
    return MarketQuote(
      symbol: symbol,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      freshness: freshness ?? this.freshness,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [symbol, price, change24h, freshness, updatedAt];
}

QuoteFreshness combineFreshness(QuoteFreshness a, QuoteFreshness b) {
  if (a == QuoteFreshness.disconnected || b == QuoteFreshness.disconnected) {
    return QuoteFreshness.disconnected;
  }
  if (a == QuoteFreshness.stale || b == QuoteFreshness.stale) {
    return QuoteFreshness.stale;
  }
  return QuoteFreshness.live;
}
