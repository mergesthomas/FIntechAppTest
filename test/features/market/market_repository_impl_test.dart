import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/depth_book.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/repositories/market_repository_impl.dart';
import 'package:fintech_app_test/features/market/domain/entities/order_book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/paper_harness.dart';

void main() {
  test('market asset stays stale on the fixture feed', () async {
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final asset = await repo.getAsset(Currency.btc);
    expect(asset.getRight().toNullable()?.freshness, QuoteFreshness.stale);
    expect(asset.getRight().toNullable()?.chart.period, ChartPeriod.oneDay);
    expect(asset.getRight().toNullable()?.chart.closes.length, greaterThan(1));
  });

  test('getCandles returns synthetic OHLCV on the fixture feed', () async {
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final candles = await repo.getCandles(Currency.btc, CandleInterval.h1);
    final series = candles.getRight().toNullable();
    expect(series?.interval, CandleInterval.h1);
    expect(series?.candles.length, greaterThan(1));
    expect(series?.freshness, QuoteFreshness.stale);
  });

  test('fixture order book is stale and sorted', () async {
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final book = (await repo.getOrderBook(Currency.btc)).getRight().toNullable();
    expect(book?.freshness, QuoteFreshness.stale);
    expect(book?.quote, Currency.usdt);
    expect(book?.bids, hasLength(orderBookDefaultDepth));
    expect(book?.asks, hasLength(orderBookDefaultDepth));
    expect(
      book!.bids.first.price.amount > book.bids.last.price.amount,
      isTrue,
    );
    expect(
      book.asks.first.price.amount < book.asks.last.price.amount,
      isTrue,
    );
    expect(book.bids.first.price.amount < book.asks.first.price.amount, isTrue);
  });

  test('prefers a feed depth book over the fixture', () async {
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    paper.feed.putDepth(
      DepthBook(
        symbol: 'BTCUSDT',
        bids: [
          DepthLevel(
            price: Money.parse('80000', Currency.usdt),
            quantity: Decimal.parse('0.5'),
          ),
        ],
        asks: [
          DepthLevel(
            price: Money.parse('80001', Currency.usdt),
            quantity: Decimal.parse('0.4'),
          ),
        ],
        freshness: QuoteFreshness.live,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final book = (await repo.getOrderBook(Currency.btc)).getRight().toNullable();
    expect(book?.freshness, QuoteFreshness.live);
    expect(book?.bids.first.price, Money.parse('80000', Currency.usdt));
    expect(book?.bids.first.size, Money.parse('0.5', Currency.btc));
  });

  test('unsupported pairs have no order book', () async {
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final result = await repo.getOrderBook(Currency.usd);
    expect(
      result.getLeft().toNullable(),
      const ValidationFailure('order_book_unavailable'),
    );
    expect(await repo.watchOrderBook(Currency.usd).isEmpty, isTrue);
  });
}
