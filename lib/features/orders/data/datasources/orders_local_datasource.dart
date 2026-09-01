import '../../../../core/ledger/paper_order.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/observe/settlement_breadcrumb.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/order.dart';

final class OrdersLocalDataSource {
  OrdersLocalDataSource({required PaperOrderStore store}) : _store = store;

  final PaperOrderStore _store;
  final Set<String> cancelRequests = {};

  List<TradeOrder> history(OrderTab tab) {
    return _store.byVenue(_venue(tab)).map(_map).toList();
  }

  List<TradeOrder> openForAsset(Currency asset) {
    return [
      for (final order in _store.openResting)
        if (_matches(order, asset)) _map(order),
    ];
  }

  TradeOrder? detail(String id) {
    for (final order in [
      ...history(OrderTab.trigger),
      ...history(OrderTab.limit),
      ...history(OrderTab.market),
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
    _store.setStatus(orderId, PaperOrderStatus.canceled);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SettlementStatus.inFlight;
  }

  PaperVenue _venue(OrderTab tab) {
    return switch (tab) {
      OrderTab.market => PaperVenue.market,
      OrderTab.trigger => PaperVenue.trigger,
      OrderTab.limit => PaperVenue.limit,
    };
  }

  bool _matches(PaperOrder order, Currency asset) {
    return order.pair.contains(asset.code) ||
        order.pay == asset ||
        order.receive == asset;
  }

  TradeOrder _map(PaperOrder order) {
    return TradeOrder(
      id: order.id,
      pair: order.pair,
      side: order.side == PaperSide.buy ? OrderSide.buy : OrderSide.sell,
      status: switch (order.status) {
        PaperOrderStatus.open => OrderStatus.open,
        PaperOrderStatus.filled => OrderStatus.filled,
        PaperOrderStatus.canceled => OrderStatus.canceled,
      },
      amount: order.amount,
      tab: switch (order.venue) {
        PaperVenue.market => OrderTab.market,
        PaperVenue.trigger => OrderTab.trigger,
        PaperVenue.limit => OrderTab.limit,
      },
      occurredAt: order.occurredAt,
      limitPrice: order.limitPrice,
      takeProfit: order.takeProfit,
      stopLoss: order.stopLoss,
      pay: order.pay,
      receive: order.receive,
    );
  }
}
