import 'package:equatable/equatable.dart';

import '../money/currency.dart';
import '../money/money.dart';

enum PaperSide { buy, sell }

enum PaperOrderStatus { open, filled, canceled }

enum PaperVenue { market, trigger, limit }

final class PaperOrder extends Equatable {
  const PaperOrder({
    required this.id,
    required this.requestId,
    required this.pair,
    required this.side,
    required this.status,
    required this.amount,
    required this.wallet,
    required this.venue,
    this.pay,
    this.receive,
    this.limitPrice,
    this.takeProfit,
    this.stopLoss,
    this.createdAt,
    this.filledAt,
  });

  final String id;
  final String requestId;
  final String pair;
  final PaperSide side;
  final PaperOrderStatus status;
  final Money amount;
  final String wallet;
  final PaperVenue venue;
  final Currency? pay;
  final Currency? receive;
  final Money? limitPrice;
  final Money? takeProfit;
  final Money? stopLoss;
  final DateTime? createdAt;
  final DateTime? filledAt;

  DateTime? get occurredAt => filledAt ?? createdAt;

  PaperOrder copyWith({
    PaperOrderStatus? status,
    DateTime? createdAt,
    DateTime? filledAt,
  }) {
    return PaperOrder(
      id: id,
      requestId: requestId,
      pair: pair,
      side: side,
      status: status ?? this.status,
      amount: amount,
      wallet: wallet,
      venue: venue,
      pay: pay,
      receive: receive,
      limitPrice: limitPrice,
      takeProfit: takeProfit,
      stopLoss: stopLoss,
      createdAt: createdAt ?? this.createdAt,
      filledAt: filledAt ?? this.filledAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        requestId,
        pair,
        side,
        status,
        amount,
        wallet,
        venue,
        pay,
        receive,
        limitPrice,
        takeProfit,
        stopLoss,
        createdAt,
        filledAt,
      ];
}

final class PaperOrderStore {
  final List<PaperOrder> _orders = [];

  List<PaperOrder> get all => List.unmodifiable(_orders);

  void add(PaperOrder order) {
    _orders.removeWhere((o) => o.id == order.id);
    _orders.insert(0, order);
  }

  void setStatus(String id, PaperOrderStatus status, {DateTime? filledAt}) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index < 0) {
      return;
    }
    _orders[index] = _orders[index].copyWith(
      status: status,
      filledAt: filledAt,
    );
  }

  PaperOrder? byId(String id) {
    for (final order in _orders) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  List<PaperOrder> byVenue(PaperVenue venue) {
    return _orders.where((o) => o.venue == venue).toList();
  }

  List<PaperOrder> get openResting {
    return _orders
        .where(
          (o) =>
              o.status == PaperOrderStatus.open &&
              (o.venue == PaperVenue.limit || o.venue == PaperVenue.trigger),
        )
        .toList();
  }
}
