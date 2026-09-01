import 'package:fintech_app_test/app.dart';
import 'package:fintech_app_test/core/di/providers.dart';
import 'package:fintech_app_test/core/fixtures/news_feed_fixture.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/notice/notice_copy.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/core/widgets/asset_list_row.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDashboard(
    WidgetTester tester, {
    QuoteFreshness freshness = QuoteFreshness.stale,
  }) async {
    final store = InMemorySecureStore();
    await store.write(AuthStoreKeys.sessionToken, 'token');
    await store.write(AuthStoreKeys.sessionPhone, '6912345678');
    await store.write(AuthStoreKeys.biometricEnabled, '0');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWith((ref) => store),
          marketFeedProvider.overrideWith(
            (ref) => InMemoryMarketFeed(connection: freshness),
          ),
        ],
        child: const FintechApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('restored session shows stale portfolio', (tester) async {
    await pumpDashboard(tester);

    expect(find.byKey(const Key('net_worth')), findsOneWidget);
    expect(find.byKey(const Key('credit_hub')), findsNothing);
    expect(find.byKey(const Key('savings_hub')), findsNothing);
    expect(find.textContaining('stale'), findsWidgets);
    expect(find.byKey(const Key('trade_buy')), findsNothing);
    expect(find.byKey(const Key('add_funds')), findsNothing);
    expect(find.byKey(const Key('trade_exchange')), findsNothing);
    expect(find.byKey(const Key('nav_exchange')), findsOneWidget);
    expect(find.byKey(const Key('nav_futures')), findsNothing);
    expect(find.byKey(const Key('trade_futures')), findsNothing);
    expect(find.text('Futures'), findsNothing);
    expect(find.text('Nexo'), findsNothing);
  });

  testWidgets('period chip updates chart without a full-screen reload', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.byKey(const Key('net_worth')), findsOneWidget);
    expect(find.byKey(const Key('period_oneDay')), findsOneWidget);
    expect(find.byKey(const Key('period_all')), findsOneWidget);

    await tester.tap(find.byKey(const Key('period_oneDay')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('net_worth')), findsOneWidget);
    expect(find.byKey(const Key('nav_exchange')), findsOneWidget);
    expect(find.byKey(const Key('period_oneDay')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('net_worth')), findsOneWidget);
  });

  testWidgets('holdings list shows seeded BTC DOGE PEPE and USDC', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.dragUntilVisible(
      find.byKey(const Key('holding_BTC')),
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('Holdings'), findsOneWidget);
    expect(find.byKey(const Key('holding_BTC')), findsOneWidget);
    expect(find.byKey(const Key('holding_DOGE')), findsOneWidget);
    expect(find.byKey(const Key('holding_PEPE')), findsOneWidget);
    expect(find.byKey(const Key('holding_USDC')), findsOneWidget);
    expect(find.textContaining('0.15 BTC'), findsOneWidget);
    expect(find.textContaining('10,000 USDC'), findsOneWidget);
  });

  testWidgets(
    'hovering the portfolio chart previews a sample and leaving restores current',
    (tester) async {
      await pumpDashboard(tester);

      final liveWorth =
          tester.widget<Text>(find.byKey(const Key('net_worth'))).data;
      expect(find.byKey(const Key('chart_scrub_label')), findsNothing);
      expect(find.byKey(const Key('chart_scrub_marker')), findsNothing);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      final box = tester.getRect(find.byKey(const Key('portfolio_chart')));
      await gesture.moveTo(box.centerLeft + const Offset(12, 0));
      await tester.pump();

      expect(find.byKey(const Key('chart_scrub_label')), findsOneWidget);
      expect(find.byKey(const Key('chart_scrub_marker')), findsOneWidget);

      await gesture.moveTo(box.bottomRight + const Offset(24, 24));
      await tester.pump();

      expect(find.byKey(const Key('chart_scrub_label')), findsNothing);
      expect(find.byKey(const Key('chart_scrub_marker')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('net_worth'))).data,
        liveWorth,
      );
    },
  );

  testWidgets('ALL chip reloads the chart without a full-screen reload', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.byKey(const Key('period_all')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('net_worth')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.textContaining('% · ALL'), findsOneWidget);
  });

  testWidgets('watchlist plus opens a searchable catalog screen', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.dragUntilVisible(
      find.byKey(const Key('watchlist_add')),
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_add')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add_watchlist_page')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const Key('watchlist_search')), findsOneWidget);
    expect(find.byType(AssetListRow), findsWidgets);
    expect(find.byKey(const Key('watchlist_add_SOL')), findsOneWidget);
    expect(find.text('Solana · stale'), findsOneWidget);
    expect(find.text(r'$148.20'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('watchlist_search')),
      'cardano',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist_add_ADA')), findsOneWidget);
    expect(find.byKey(const Key('watchlist_add_SOL')), findsNothing);
    expect(find.text('Cardano · stale'), findsOneWidget);
  });

  testWidgets('watchlist plus adds a candidate crypto', (tester) async {
    await pumpDashboard(tester);

    await tester.dragUntilVisible(
      find.byKey(const Key('watchlist_add')),
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_add')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('watchlist_add_SOL')), findsOneWidget);
    await tester.tap(find.byKey(const Key('watchlist_add_SOL')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add_watchlist_page')), findsNothing);

    await tester.dragUntilVisible(
      find.byKey(const Key('watchlist_SOL')),
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -300),
    );
    expect(find.byKey(const Key('watchlist_SOL')), findsOneWidget);
  });

  testWidgets('added catalog coin opens market without a raw failure', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.dragUntilVisible(
      find.byKey(const Key('watchlist_add')),
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('watchlist_search')), 'cardano');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('watchlist_add_ADA')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(NoticeCopy.watchlistAdded('ADA')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('ValidationFailure'), findsNothing);

    await tester.dragUntilVisible(
      find.byKey(const Key('watchlist_ADA')),
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -300),
    );
    await tester.tap(find.byKey(const Key('watchlist_ADA')));
    await tester.pumpAndSettle();

    expect(find.textContaining('ValidationFailure'), findsNothing);
    expect(find.byKey(const Key('market_price')), findsOneWidget);
  });

  testWidgets('live feed does not print live on home', (tester) async {
    await pumpDashboard(tester, freshness: QuoteFreshness.live);

    expect(find.byKey(const Key('net_worth')), findsOneWidget);
    expect(find.text('live'), findsNothing);
  });

  testWidgets('disconnected feed shows a persistent offline banner', (
    tester,
  ) async {
    await pumpDashboard(tester, freshness: QuoteFreshness.disconnected);

    expect(find.byKey(const Key('feed_offline_banner')), findsOneWidget);
    expect(find.text(NoticeCopy.feedDisconnected), findsOneWidget);
  });

  testWidgets('dashboard and view-all show four Dogecoin stories', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.dragUntilVisible(
      find.byKey(const Key('news_all')),
      find.byKey(const Key('dashboard_scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    for (final item in NewsFeedFixture.preview()) {
      expect(find.byKey(Key('news_preview_${item.id}')), findsOneWidget);
      expect(find.text(item.headline), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('news_all')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('news_feed_scroll')), findsOneWidget);
    for (final item in NewsFeedFixture.preview()) {
      expect(find.byKey(Key('news_item_${item.id}')), findsOneWidget);
      expect(find.text(item.headline), findsWidgets);
      expect(find.text('${item.source} · ${item.age}'), findsOneWidget);
    }
  });
}
