import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/market/watch_market_connection.dart';
import 'package:fintech_app_test/core/notice/market_connection_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts from the feed and follows disconnect', () async {
    final feed = InMemoryMarketFeed(connection: QuoteFreshness.stale);
    final cubit = MarketConnectionCubit(WatchMarketConnection(feed));
    expect(cubit.state, QuoteFreshness.stale);
    feed.setConnection(QuoteFreshness.disconnected);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, QuoteFreshness.disconnected);
    await cubit.close();
    feed.dispose();
  });
}
