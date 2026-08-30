import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/ledger/paper_settler.dart';
import 'core/market/binance_market_feed.dart';
import 'core/secure/flutter_secure_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        secureStoreProvider.overrideWith((ref) => FlutterSecureStore()),
        paperSettlerProvider.overrideWith((ref) => const DelayedPaperSettler()),
        marketFeedProvider.overrideWith((ref) {
          final feed = BinanceMarketFeed(
            flavor: ref.watch(flavorConfigProvider),
            clock: ref.watch(appClockProvider),
          );
          unawaited(feed.connect());
          ref.onDispose(feed.dispose);
          return feed;
        }),
      ],
      child: const FintechApp(),
    ),
  );
}
