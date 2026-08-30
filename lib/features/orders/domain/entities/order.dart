import 'package:equatable/equatable.dart';

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
    required this.wallet,
    required this.tab,
  });

  final String id;
  final String pair;
  final OrderSide side;
  final OrderStatus status;
  final Money amount;
  final String wallet;
  final OrderTab tab;

  @override
  List<Object?> get props => [id, pair, side, status, amount, wallet, tab];
}
