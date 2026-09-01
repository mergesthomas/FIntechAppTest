import 'dart:async';

import 'market_feed.dart';
import 'market_quote.dart';
import 'quote_freshness.dart';

/// Samples [MarketFeed.connection] from the current value and each quote.
final class WatchMarketConnection {
  WatchMarketConnection(this._feed);

  final MarketFeed _feed;
  StreamController<QuoteFreshness>? _controller;
  StreamSubscription<MarketQuote>? _quotes;

  QuoteFreshness get current => _feed.connection;

  Stream<QuoteFreshness> call() {
    final controller = _controller ??= StreamController<QuoteFreshness>.broadcast();
    _quotes ??= _feed.quotes.listen((_) {
      if (!controller.isClosed) {
        controller.add(_feed.connection);
      }
    });
    if (!controller.isClosed) {
      controller.add(_feed.connection);
    }
    return controller.stream.distinct();
  }

  void dispose() {
    _quotes?.cancel();
    _quotes = null;
    _controller?.close();
    _controller = null;
  }
}
