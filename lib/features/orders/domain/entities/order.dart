import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';

enum OrderTab { trigger, limit, market }

enum OrderSide { sell, buy }

enum OrderStatus { canceled, open, filled }

final class TradeOrder extends Equatable {
  const TradeOrder({
    required this.id,
    required this.pair,
    required this.side,
    required this.status,
    required this.amount,
    required this.tab,
    this.wallet = '',
    this.occurredAt,
    this.limitPrice,
    this.takeProfit,
    this.stopLoss,
    this.pay,
    this.receive,
  });

  final String id;
  final String pair;
  final OrderSide side;
  final OrderStatus status;
  final Money amount;
  final String wallet;
  final OrderTab tab;
  final DateTime? occurredAt;
  final Money? limitPrice;
  final Money? takeProfit;
  final Money? stopLoss;
  final Currency? pay;
  final Currency? receive;

  @override
  List<Object?> get props => [
        id,
        pair,
        side,
        status,
        amount,
        wallet,
        tab,
        occurredAt,
        limitPrice,
        takeProfit,
        stopLoss,
        pay,
        receive,
      ];
}
