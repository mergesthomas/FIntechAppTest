import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/card.dart';

final class CardLocalDataSource {
  CardSnapshot snapshot = CardSnapshot(
    status: CardStatus.frozen,
    balances: CardBalances(
      eurx: Money.parse('-1.16', Currency.eurx),
      usdApprox: Money.parse('-1.35', Currency.usd),
    ),
  );

  CardSnapshot unfreeze() {
    if (snapshot.balances.eligibleToUnfreeze) {
      snapshot = CardSnapshot(
        status: CardStatus.active,
        balances: snapshot.balances,
      );
    }
    return snapshot;
  }
}
