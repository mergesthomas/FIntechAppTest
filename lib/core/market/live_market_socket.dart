/// Test seam for Binance WebSocket. Production wraps [WebSocket].
abstract interface class LiveMarketSocket {
  Stream<Object?> get messages;

  Future<void> close();
}

typedef OpenLiveMarketSocket = Future<LiveMarketSocket> Function(Uri uri);
