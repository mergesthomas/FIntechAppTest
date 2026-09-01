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
    cashbackEarned: Money.parse('317.50', Currency.usd),
  );

  static const fixturePin = '1234';

  CardSnapshot unfreeze() {
    if (snapshot.balances.eligibleToUnfreeze) {
      snapshot = CardSnapshot(
        status: CardStatus.active,
        balances: snapshot.balances,
        last4: snapshot.last4,
        network: snapshot.network,
        modeLabel: snapshot.modeLabel,
        applePayAdded: snapshot.applePayAdded,
        cashbackEarned: snapshot.cashbackEarned,
      );
    }
    return snapshot;
  }

  CardSnapshot freeze() {
    snapshot = CardSnapshot(
      status: CardStatus.frozen,
      balances: snapshot.balances,
      last4: snapshot.last4,
      network: snapshot.network,
      modeLabel: snapshot.modeLabel,
      applePayAdded: snapshot.applePayAdded,
      cashbackEarned: snapshot.cashbackEarned,
    );
    return snapshot;
  }
}
