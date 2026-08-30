import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/observe/settlement_breadcrumb.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/order.dart';

final class OrdersLocalDataSource {
  final Set<String> cancelRequests = {};

  List<TradeOrder> history(OrderTab tab) {
    final all = [
      TradeOrder(
        id: 'ord-1',
        pair: 'BTCUSDT',
        side: OrderSide.sell,
        status: OrderStatus.canceled,
        amount: Money.parse('0.01', Currency.btc),
        wallet: 'Credit Wallet',
        tab: OrderTab.trigger,
      ),
      TradeOrder(
        id: 'ord-2',
        pair: 'ETHUSDT',
        side: OrderSide.buy,
        status: OrderStatus.canceled,
        amount: Money.parse('0.50', Currency.eth),
        wallet: 'Credit Wallet',
        tab: OrderTab.limit,
      ),
    ];
    return all.where((o) => o.tab == tab).toList();
  }

  TradeOrder? detail(String id) {
    for (final order in [
      ...history(OrderTab.trigger),
      ...history(OrderTab.limit),
    ]) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  SettlementStatus cancel({required String requestId, required String orderId}) {
    if (cancelRequests.contains(requestId)) {
      return SettlementStatus.inFlight;
    }
    cancelRequests.add(requestId);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SettlementStatus.inFlight;
  }
}
