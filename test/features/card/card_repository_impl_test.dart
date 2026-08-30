import 'package:fintech_app_test/features/card/data/datasources/card_local_datasource.dart';
import 'package:fintech_app_test/features/card/data/repositories/card_repository_impl.dart';
import 'package:fintech_app_test/features/card/domain/entities/card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture card is frozen with negative EURx', () async {
    final repo = CardRepositoryImpl(CardLocalDataSource());
    final snapshot = await repo.getSnapshot();
    expect(snapshot.getRight().toNullable()?.status, CardStatus.frozen);
    expect(snapshot.getRight().toNullable()?.balances.eurx.isNegative, isTrue);
  });
}
