import 'package:equatable/equatable.dart';

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
  });

  final String id;
  final String requestId;
  final String pair;
  final PaperSide side;
  final PaperOrderStatus status;
  final Money amount;
  final String wallet;
  final PaperVenue venue;

  PaperOrder copyWith({PaperOrderStatus? status}) {
    return PaperOrder(
      id: id,
      requestId: requestId,
      pair: pair,
      side: side,
      status: status ?? this.status,
      amount: amount,
      wallet: wallet,
      venue: venue,
    );
  }

  @override
  List<Object?> get props =>
      [id, requestId, pair, side, status, amount, wallet, venue];
}

final class PaperOrderStore {
  final List<PaperOrder> _orders = [];

  List<PaperOrder> get all => List.unmodifiable(_orders);

  void add(PaperOrder order) {
    _orders.removeWhere((o) => o.id == order.id);
    _orders.insert(0, order);
  }

  void setStatus(String id, PaperOrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index < 0) {
      return;
    }
    _orders[index] = _orders[index].copyWith(status: status);
  }

  List<PaperOrder> byVenue(PaperVenue venue) {
    return _orders.where((o) => o.venue == venue).toList();
  }
}
