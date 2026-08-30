import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/earn/data/datasources/earn_local_datasource.dart';
import 'package:fintech_app_test/features/earn/data/repositories/earn_repository_impl.dart';
import 'package:fintech_app_test/features/earn/domain/usecases/earn_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late EarnRepositoryImpl repo;

  setUp(() {
    auth = MockAuthRepository();
    repo = EarnRepositoryImpl(EarnLocalDataSource());
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('StopEarning refuses without step-up', () async {
    final result = await StopEarning(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    )((requestId: 'stop-1', stepUp: false));
    expect(result.getLeft().toNullable(), isA<StepUpFailure>());
  });

  test('StopEarning returns inFlight when stepped up', () async {
    final result = await StopEarning(
      RequireSession(auth),
      GetEligibility(auth),
      repo,
    )((requestId: 'stop-1', stepUp: true));
    expect(result.getRight().toNullable(), SettlementStatus.inFlight);
  });

  test('hub overview requires session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await GetSavingsHubOverview(RequireSession(auth), repo)(
      const NoParams(),
    );
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });
}
