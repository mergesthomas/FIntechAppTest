import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/swap/data/datasources/swap_local_datasource.dart';
import 'package:fintech_app_test/features/swap/data/repositories/swap_repository_impl.dart';
import 'package:fintech_app_test/features/swap/domain/entities/swap.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';

void main() {
  test('swap quotes are stale fixtures', () async {
    final paper = PaperHarness();
    final repo = SwapRepositoryImpl(
      SwapLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    final quote = await repo.getQuote(
      from: Currency.nexo,
      to: Currency.eurx,
      amount: Money.parse('10', Currency.nexo),
      wallet: SwapWallet.savings,
    );
    expect(quote.getRight().toNullable()?.freshness, QuoteFreshness.stale);
  });
}
