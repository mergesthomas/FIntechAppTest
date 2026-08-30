import 'package:fintech_app_test/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:fintech_app_test/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:fintech_app_test/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture history is canceled sell on trigger tab', () async {
    final repo = OrdersRepositoryImpl(OrdersLocalDataSource());
    final history = await repo.getHistory(OrderTab.trigger);
    expect(history.getRight().toNullable()?.first.status, OrderStatus.canceled);
    expect(history.getRight().toNullable()?.first.side, OrderSide.sell);
  });
}
