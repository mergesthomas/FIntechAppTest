import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../money/money.dart';
import 'quote_freshness.dart';

final class DepthLevel extends Equatable {
  const DepthLevel({required this.price, required this.quantity});

  final Money price;
  final Decimal quantity;

  @override
  List<Object?> get props => [price, quantity];
}

final class DepthBook extends Equatable {
  const DepthBook({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.freshness,
    required this.updatedAt,
  });

  final String symbol;
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;
  final QuoteFreshness freshness;
  final DateTime updatedAt;

  DepthBook copyWith({QuoteFreshness? freshness}) {
    return DepthBook(
      symbol: symbol,
      bids: bids,
      asks: asks,
      freshness: freshness ?? this.freshness,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [symbol, bids, asks, freshness, updatedAt];
}
