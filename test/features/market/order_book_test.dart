import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/market/domain/entities/order_book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  OrderBookLevel bid(String price, String size) {
    return OrderBookLevel(
      side: OrderBookSide.bid,
      price: Money.parse(price, Currency.usdt),
      size: Money.parse(size, Currency.btc),
    );
  }

  OrderBookLevel ask(String price, String size) {
    return OrderBookLevel(
      side: OrderBookSide.ask,
      price: Money.parse(price, Currency.usdt),
      size: Money.parse(size, Currency.btc),
    );
  }

  test('normalizes bids high-to-low and asks low-to-high', () {
    final book = OrderBook.normalized(
      currency: Currency.btc,
      quote: Currency.usdt,
      bids: [bid('100', '1'), bid('102', '1'), bid('101', '1')],
      asks: [ask('104', '1'), ask('103', '1'), ask('105', '1')],
      freshness: QuoteFreshness.stale,
      updatedAt: at,
    );
    expect(
      book.bids.map((level) => level.price.amount.toString()),
      ['102', '101', '100'],
    );
    expect(
      book.asks.map((level) => level.price.amount.toString()),
      ['103', '104', '105'],
    );
  });

  test('trimmed keeps the best N levels', () {
    final book = OrderBook.normalized(
      currency: Currency.btc,
      quote: Currency.usdt,
      bids: [bid('3', '1'), bid('2', '1'), bid('1', '1')],
      asks: [ask('4', '1'), ask('5', '1'), ask('6', '1')],
      freshness: QuoteFreshness.stale,
      updatedAt: at,
      depth: 2,
    );
    expect(book.bids, hasLength(2));
    expect(book.asks, hasLength(2));
    expect(book.bids.first.price, Money.parse('3', Currency.usdt));
    expect(book.asks.first.price, Money.parse('4', Currency.usdt));
  });

  test('findLevel matches side and price', () {
    final book = OrderBook.normalized(
      currency: Currency.btc,
      quote: Currency.usdt,
      bids: [bid('100', '2')],
      asks: [ask('101', '3')],
      freshness: QuoteFreshness.stale,
      updatedAt: at,
    );
    expect(
      book.findLevel(OrderBookSide.bid, Money.parse('100', Currency.usdt))?.size,
      Money.parse('2', Currency.btc),
    );
    expect(
      book.findLevel(OrderBookSide.ask, Money.parse('100', Currency.usdt)),
      isNull,
    );
    expect(
      book.findLevel(OrderBookSide.bid, Money.parse('99', Currency.usdt)),
      isNull,
    );
  });
}
