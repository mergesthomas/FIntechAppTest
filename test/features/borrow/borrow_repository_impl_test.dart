import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/borrow/data/datasources/borrow_local_datasource.dart';
import 'package:fintech_app_test/features/borrow/data/repositories/borrow_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('borrow quotes are stale and catalog stays visible at 0 available', () async {
    final repo = BorrowRepositoryImpl(BorrowLocalDataSource());
    final overview = await repo.getOverview();
    final products = await repo.getProducts();
    final quote = await repo.getBorrowQuote(
      productId: 'classic',
      amount: Money.parse('100', Currency.usdc),
    );
    expect(overview.getRight().toNullable()?.available.isPositive, isFalse);
    expect(products.getRight().toNullable(), isNotEmpty);
    expect(quote.getRight().toNullable()?.freshness, QuoteFreshness.stale);
  });
}
