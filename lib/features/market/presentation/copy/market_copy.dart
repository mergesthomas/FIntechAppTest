import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/notice/failure_message.dart';

abstract final class MarketCopy {
  static const volume = 'Vol';
  static const resetZoom = 'Reset';
  static const orderBook = 'Order book';
  static const bids = 'Bids';
  static const asks = 'Asks';
  static const size = 'Size';
  static const price = 'Price';
  static const spread = 'Spread';
  static const bookUnavailable = 'Order book is unavailable for this asset.';
  static const bookOffline =
      'The order book is offline. It cannot set a price.';
  static const bookSelectFailed = 'Could not use that price.';

  static String bookFailure(Failure failure) {
    return switch (failure) {
      StaleQuoteFailure() => bookOffline,
      _ => FailureMessage.map(failure),
    };
  }

  static String intervalLabel(CandleInterval interval) {
    return switch (interval) {
      CandleInterval.m1 => '1m',
      CandleInterval.m5 => '5m',
      CandleInterval.m15 => '15m',
      CandleInterval.h1 => '1h',
      CandleInterval.h4 => '4h',
      CandleInterval.d1 => '1D',
      CandleInterval.w1 => '1W',
    };
  }
}
