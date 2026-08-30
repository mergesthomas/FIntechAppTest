import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/security_settings/domain/entities/security_settings.dart';
import 'package:fintech_app_test/features/security_settings/domain/repositories/security_repository.dart';
import 'package:fintech_app_test/features/security_settings/domain/usecases/security_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecurityRepository extends Mock implements SecurityRepository {}

void main() {
  late MockAuthRepository auth;
  late MockSecurityRepository security;

  setUp(() {
    auth = MockAuthRepository();
    security = MockSecurityRepository();
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('GetSecuritySettings refuses without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await GetSecuritySettings(
      RequireSession(auth),
      security,
    )(const NoParams());
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('StartCloseAccount refuses without step-up', () async {
    final result = await StartCloseAccount(RequireSession(auth), security)((
      requestId: 'close-1',
      stepUp: false,
    ));
    expect(result.getLeft().toNullable(), isA<StepUpFailure>());
    verifyNever(
      () => security.closeAccount(
        requestId: any(named: 'requestId'),
        stepUpVerified: any(named: 'stepUpVerified'),
      ),
    );
  });

  test('StartCloseAccount returns inFlight when stepped up', () async {
    when(
      () => security.closeAccount(requestId: 'close-1', stepUpVerified: true),
    ).thenAnswer((_) async => Either.right(SettlementStatus.inFlight));

    final result = await StartCloseAccount(RequireSession(auth), security)((
      requestId: 'close-1',
      stepUp: true,
    ));

    expect(result.getRight().toNullable(), SettlementStatus.inFlight);
  });

  test('RequestAccountDocument requires requestId', () async {
    final result = await RequestAccountDocument(RequireSession(auth), security)((
      kind: AccountDocumentKind.accountBalance,
      requestId: '',
    ));
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
