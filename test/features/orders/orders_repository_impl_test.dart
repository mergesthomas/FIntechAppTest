import 'package:fintech_app_test/core/ledger/paper_ledger.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:fintech_app_test/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:fintech_app_test/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';

void main() {
  test('paper history is empty until a swap is placed', () async {
    final repo = OrdersRepositoryImpl(
      OrdersLocalDataSource(store: PaperOrderStore()),
    );
    final history = await repo.getHistory(OrderTab.trigger);
    expect(history.getRight().toNullable(), isEmpty);
  });

  test('openForAsset returns resting paper orders for that coin', () async {
    final paper = PaperHarness();
    await paper.ledger.placeHold(
      requestId: 'hold-1',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
        id: 'ord-doge',
        requestId: 'hold-1',
        pair: 'USDC/DOGE',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: Money.parse('10', Currency.usdc),
        wallet: 'savings',
        venue: PaperVenue.limit,
        pay: Currency.usdc,
        receive: Currency.doge,
      ),
    );
    final repo = OrdersRepositoryImpl(
      OrdersLocalDataSource(store: paper.store),
      ledger: paper.ledger,
    );
    final doge = await repo.getOpenForAsset(Currency.doge);
    final btc = await repo.getOpenForAsset(Currency.btc);
    expect(doge.getRight().toNullable()?.single.id, 'ord-doge');
    expect(btc.getRight().toNullable(), isEmpty);
  });
}
