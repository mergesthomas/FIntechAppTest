import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/candle_series.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 1, 15, 12, 7);

  test('synthetic candles stay Decimal and include classic patterns', () {
    final series = syntheticCandleSeries(
      last: Decimal.parse('100'),
      interval: CandleInterval.m15,
      now: now,
    );
    expect(series.freshness, QuoteFreshness.stale);
    expect(series.candles.length, 240);
    expect(series.candles.first.open, isA<Decimal>());
    expect(series.candles[series.candles.length - 4].isDoji, isTrue);
    expect(series.candles[series.candles.length - 3].isHammer, isTrue);
    expect(series.candles[series.candles.length - 2].isInvertedHammer, isTrue);
    expect(series.candles.last.isShootingStar, isTrue);
  });

  test('hammer lower wick is at least twice the body', () {
    final series = syntheticCandleSeries(
      last: Decimal.parse('100'),
      interval: CandleInterval.h1,
      now: now,
    );
    final hammer = series.candles[series.candles.length - 3];
    expect(hammer.lowerWick >= hammer.body * Decimal.fromInt(2), isTrue);
    expect(hammer.upperWick <= hammer.body, isTrue);
  });

  test('doji body is a small fraction of the range', () {
    final series = syntheticCandleSeries(
      last: Decimal.parse('50'),
      interval: CandleInterval.h1,
      now: now,
    );
    final doji = series.candles[series.candles.length - 4];
    expect(doji.isDoji, isTrue);
    expect(doji.body * Decimal.fromInt(20) <= doji.range, isTrue);
  });

  test('applyTick updates the forming candle high/low/close', () {
    final open = candleOpenTime(now, CandleInterval.m15);
    final series = CandleSeries(
      interval: CandleInterval.m15,
      freshness: QuoteFreshness.live,
      candles: [
        OhlcvCandle(
          openTime: open,
          open: Decimal.parse('100'),
          high: Decimal.parse('101'),
          low: Decimal.parse('99'),
          close: Decimal.parse('100.5'),
          volume: Decimal.parse('10'),
        ),
      ],
    );
    final updated = series.applyTick(
      price: Decimal.parse('102'),
      at: open.add(const Duration(minutes: 3)),
    );
    expect(updated.candles, hasLength(1));
    expect(updated.latest?.close, Decimal.parse('102'));
    expect(updated.latest?.high, Decimal.parse('102'));
    expect(updated.latest?.open, Decimal.parse('100'));
  });

  test('applyTick opens a new candle after the interval rolls', () {
    final open = DateTime.utc(2026, 1, 15, 12);
    final series = CandleSeries(
      interval: CandleInterval.h1,
      freshness: QuoteFreshness.live,
      candles: [
        OhlcvCandle(
          openTime: open,
          open: Decimal.parse('10'),
          high: Decimal.parse('11'),
          low: Decimal.parse('9'),
          close: Decimal.parse('10.5'),
          volume: Decimal.one,
        ),
      ],
    );
    final next = series.applyTick(
      price: Decimal.parse('10.8'),
      at: DateTime.utc(2026, 1, 15, 13, 1),
    );
    expect(next.candles, hasLength(2));
    expect(next.latest?.open, Decimal.parse('10.5'));
    expect(next.latest?.close, Decimal.parse('10.8'));
    expect(next.latest?.openTime, DateTime.utc(2026, 1, 15, 13));
  });
}
