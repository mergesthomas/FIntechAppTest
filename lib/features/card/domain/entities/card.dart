import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

enum CardStatus { none, frozen, active }

enum RestoreRail { funding, swap }

final class CardBalances extends Equatable {
  const CardBalances({required this.eurx, required this.usdApprox});

  final Money eurx;
  final Money usdApprox;

  bool get eligibleToUnfreeze => !eurx.isNegative;

  @override
  List<Object?> get props => [eurx, usdApprox];
}

final class CardSnapshot extends Equatable {
  const CardSnapshot({
    required this.status,
    required this.balances,
  });

  final CardStatus status;
  final CardBalances balances;

  @override
  List<Object?> get props => [status, balances];
}
