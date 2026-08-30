import 'package:fintech_app_test/core/error/failure.dart';
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

  test('restore returns the chosen existing rail', () async {
    final result = await RestoreCardBalance(RequireSession(auth))(
      RestoreRail.funding,
    );
    expect(result.getRight().toNullable(), RestoreRail.funding);
  });
}
