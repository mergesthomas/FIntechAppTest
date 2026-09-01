import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/card/data/datasources/card_local_datasource.dart';
import 'package:fintech_app_test/features/card/data/repositories/card_repository_impl.dart';
import 'package:fintech_app_test/features/card/domain/entities/card.dart';
import 'package:fintech_app_test/features/card/domain/usecases/card_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late CardRepositoryImpl repo;

  setUp(() {
    auth = MockAuthRepository();
    repo = CardRepositoryImpl(CardLocalDataSource());
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('frozen status is first-class and EURx can be negative', () async {
    final result = await GetCardStatus(RequireSession(auth), repo)(
      const NoParams(),
    );
    final snapshot = result.getRight().toNullable();
    expect(snapshot?.status, CardStatus.frozen);
    expect(snapshot?.balances.eurx.isNegative, isTrue);
  });

  test('unfreeze refuses a negative EURx balance', () async {
    final result = await UnfreezeCard(RequireSession(auth), repo)(
      const NoParams(),
    );
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('reveal pin requires step-up', () async {
    final result = await RevealCardPin(RequireSession(auth), repo)(
      (stepUp: false),
    );
    expect(result.getLeft().toNullable(), isA<StepUpFailure>());
  });

  test('freeze marks the card frozen', () async {
    final local = CardLocalDataSource();
    local.snapshot = CardSnapshot(
      status: CardStatus.active,
      balances: CardBalances(
        eurx: Money.parse('10', Currency.eurx),
        usdApprox: Money.parse('11', Currency.usd),
      ),
    );
    final active = CardRepositoryImpl(local);
    final result = await FreezeCard(RequireSession(auth), active)(
      const NoParams(),
    );
    expect(result.getRight().toNullable()?.status, CardStatus.frozen);
  });

  test('restore returns the chosen existing rail', () async {
    final result = await RestoreCardBalance(RequireSession(auth))(
      RestoreRail.swap,
    );
    expect(result.getRight().toNullable(), RestoreRail.swap);
  });
}
