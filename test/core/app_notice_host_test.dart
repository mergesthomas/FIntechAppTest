import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/market/watch_market_connection.dart';
import 'package:fintech_app_test/core/notice/app_notice_host.dart';
import 'package:fintech_app_test/core/notice/market_connection_cubit.dart';
import 'package:fintech_app_test/core/notice/notice_copy.dart';
import 'package:fintech_app_test/core/notice/user_notice.dart';
import 'package:fintech_app_test/core/notice/user_notice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required UserNoticeCubit notices,
    required MarketConnectionCubit connection,
  }) {
    return tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: notices),
          BlocProvider.value(value: connection),
        ],
        child: MaterialApp(
          builder: (context, child) {
            return AppNoticeHost(child: child ?? const SizedBox.shrink());
          },
          home: const Scaffold(body: Text('body')),
        ),
      ),
    );
  }

  testWidgets('shows a success snackbar and hides the offline banner when stale', (
    tester,
  ) async {
    final notices = UserNoticeCubit();
    final feed = InMemoryMarketFeed(connection: QuoteFreshness.stale);
    final connection = MarketConnectionCubit(WatchMarketConnection(feed));
    addTearDown(() async {
      await notices.close();
      await connection.close();
      feed.dispose();
    });

    await pumpHost(tester, notices: notices, connection: connection);

    expect(find.text('body'), findsOneWidget);
    expect(find.byKey(const Key('feed_offline_banner')), findsNothing);

    notices.show(UserNotice.success(NoticeCopy.watchlistAdded('SOL')));
    await tester.pump();
    expect(find.text(NoticeCopy.watchlistAdded('SOL')), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.text('body'))).clearSnackBars();
    await tester.pump();
  });

  testWidgets('shows a persistent banner when the feed is disconnected', (
    tester,
  ) async {
    final notices = UserNoticeCubit();
    final feed = InMemoryMarketFeed(connection: QuoteFreshness.disconnected);
    final connection = MarketConnectionCubit(WatchMarketConnection(feed));
    addTearDown(() async {
      await notices.close();
      await connection.close();
      feed.dispose();
    });

    await pumpHost(tester, notices: notices, connection: connection);

    expect(find.byKey(const Key('feed_offline_banner')), findsOneWidget);
    expect(find.text(NoticeCopy.feedDisconnected), findsOneWidget);
  });
}
