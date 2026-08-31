import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';

const orderBookDefaultDepth = 10;
const orderBookMaxDepth = 20;

enum OrderBookSide { bid, ask }

final class OrderBookLevel extends Equatable {
  const OrderBookLevel({
    required this.side,
    required this.price,
    required this.size,
  });

  final OrderBookSide side;
  final Money price;
  final Money size;

  @override
  List<Object?> get props => [side, price, size];
}

final class OrderBook extends Equatable {
  const OrderBook({
    required this.currency,
    required this.quote,
    required this.bids,
    required this.asks,
    required this.freshness,
    required this.updatedAt,
  });

  factory OrderBook.normalized({
    required Currency currency,
    required Currency quote,
    required List<OrderBookLevel> bids,
    required List<OrderBookLevel> asks,
    required QuoteFreshness freshness,
    required DateTime updatedAt,
    int depth = orderBookDefaultDepth,
  }) {
    final limited = depth.clamp(1, orderBookMaxDepth);
    final sortedBids = [
      for (final level in bids)
        if (level.side == OrderBookSide.bid &&
            level.price.currency == quote &&
            level.size.currency == currency)
          level,
    ]..sort((a, b) => b.price.amount.compareTo(a.price.amount));
    final sortedAsks = [
      for (final level in asks)
        if (level.side == OrderBookSide.ask &&
            level.price.currency == quote &&
            level.size.currency == currency)
          level,
    ]..sort((a, b) => a.price.amount.compareTo(b.price.amount));
    return OrderBook(
      currency: currency,
      quote: quote,
      bids: sortedBids.take(limited).toList(growable: false),
      asks: sortedAsks.take(limited).toList(growable: false),
      freshness: freshness,
      updatedAt: updatedAt,
    );
  }

  final Currency currency;
  final Currency quote;
  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;
  final QuoteFreshness freshness;
  final DateTime updatedAt;

  OrderBook trimmed(int depth) {
    return OrderBook.normalized(
      currency: currency,
      quote: quote,
      bids: bids,
      asks: asks,
      freshness: freshness,
      updatedAt: updatedAt,
      depth: depth,
    );
  }

  OrderBook copyWith({QuoteFreshness? freshness}) {
    return OrderBook(
      currency: currency,
      quote: quote,
      bids: bids,
      asks: asks,
      freshness: freshness ?? this.freshness,
      updatedAt: updatedAt,
    );
  }

  OrderBookLevel? findLevel(OrderBookSide side, Money price) {
    final levels = side == OrderBookSide.bid ? bids : asks;
    for (final level in levels) {
      if (level.price == price) {
        return level;
      }
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [currency, quote, bids, asks, freshness, updatedAt];
}

final class BookTicketDraft extends Equatable {
  const BookTicketDraft({
    required this.currency,
    required this.quote,
    required this.side,
    required this.limitPrice,
    required this.size,
    required this.freshness,
  });

  final Currency currency;
  final Currency quote;
  final OrderBookSide side;
  final Money limitPrice;
  final Money size;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props =>
      [currency, quote, side, limitPrice, size, freshness];
}
