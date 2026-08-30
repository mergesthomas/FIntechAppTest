import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/borrow/data/datasources/borrow_local_datasource.dart';
import 'package:fintech_app_test/features/borrow/data/repositories/borrow_repository_impl.dart';
import 'package:fintech_app_test/features/borrow/domain/entities/borrow.dart';
import 'package:fintech_app_test/features/borrow/domain/usecases/borrow_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late UpdateCreditLineOptimization update;

  setUp(() {
    auth = MockAuthRepository();
    update = UpdateCreditLineOptimization(
      RequireSession(auth),
      GetEligibility(auth),
      BorrowRepositoryImpl(BorrowLocalDataSource()),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('refuses dependent flags when auto-transfer is off', () async {
    final result = await update((
      requestId: 'opt-1',
      stepUp: true,
      flags: const CreditLineOptimization(
        automaticCollateralTransfer: false,
        fixedTermUnlock: true,
        lowInterestBorrowing: false,
      ),
    ));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('accepts auto-transfer on with step-up', () async {
    final result = await update((
      requestId: 'opt-1',
      stepUp: true,
      flags: const CreditLineOptimization(
        automaticCollateralTransfer: true,
        fixedTermUnlock: true,
        lowInterestBorrowing: true,
      ),
    ));
    expect(result.getRight().toNullable(), SettlementStatus.inFlight);
  });
}
