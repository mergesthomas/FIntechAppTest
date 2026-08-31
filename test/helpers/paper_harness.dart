import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/ledger/paper_ledger.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/ledger/paper_settler.dart';
import 'package:fintech_app_test/core/market/in_memory_market_feed.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';

final class PaperHarness {
  PaperHarness({
    QuoteFreshness freshness = QuoteFreshness.stale,
    AppClock clock = const SystemClock(),
  }) : feed = InMemoryMarketFeed(clock: clock, connection: freshness) {
    ledger = PaperLedger(orders: store, settler: settler, clock: clock);
  }

  final InMemoryMarketFeed feed;
  final PaperOrderStore store = PaperOrderStore();
  final PaperSettler settler = const ImmediatePaperSettler();
  late final PaperLedger ledger;
}
