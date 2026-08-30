import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/futures/data/datasources/futures_local_datasource.dart';
import 'package:fintech_app_test/features/futures/data/repositories/futures_repository_impl.dart';
import 'package:fintech_app_test/features/futures/domain/entities/futures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quotes and marks are stale fixtures', () async {
    final repo = FuturesRepositoryImpl(FuturesLocalDataSource());
    final instrument = await repo.getInstrument();
    final quote = await repo.getQuote(
      side: FuturesSide.long,
      size: Money.parse('0.01', Currency.btc),
    );
    final details = await repo.getPositionDetails('pos-pepe');
    expect(instrument.getRight().toNullable()?.freshness, QuoteFreshness.stale);
    expect(quote.getRight().toNullable()?.freshness, QuoteFreshness.stale);
    expect(
      details.getRight().toNullable()?.markFreshness,
      QuoteFreshness.stale,
    );
  });

  test('account margin is the screenshot fixture', () async {
    final repo = FuturesRepositoryImpl(FuturesLocalDataSource());
    final account = (await repo.getAccount()).getRight().toNullable();
    expect(account?.availableMargin, Money.parse('186.25', Currency.usdt));
  });
}
