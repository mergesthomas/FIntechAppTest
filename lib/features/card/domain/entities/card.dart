import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

enum CardStatus { none, frozen, active }

enum RestoreRail { swap }

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
    this.last4 = '4036',
    this.network = 'Mastercard',
    this.modeLabel = 'Debit',
    this.applePayAdded = true,
    this.cashbackEarned,
  });

  final CardStatus status;
  final CardBalances balances;
  final String last4;
  final String network;
  final String modeLabel;
  final bool applePayAdded;
  final Money? cashbackEarned;

  @override
  List<Object?> get props => [
        status,
        balances,
        last4,
        network,
        modeLabel,
        applePayAdded,
        cashbackEarned,
      ];
}
