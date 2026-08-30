import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/funding/data/datasources/funding_local_datasource.dart';
import 'package:fintech_app_test/features/funding/data/repositories/funding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';

void main() {
  test('buy quotes are stale fixtures', () async {
    final paper = PaperHarness();
    final repo = FundingRepositoryImpl(
      FundingLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    final quote = await repo.getBuyQuote(
      asset: Currency.btc,
      spend: Money.parse('100', Currency.usd),
    );
    expect(quote.getRight().toNullable()?.freshness, QuoteFreshness.stale);
  });
}
