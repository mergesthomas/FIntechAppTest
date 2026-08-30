import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/security_settings/data/datasources/security_local_datasource.dart';
import 'package:fintech_app_test/features/security_settings/data/repositories/security_repository_impl.dart';
import 'package:fintech_app_test/features/security_settings/domain/usecases/security_usecases.dart';
import 'package:fintech_app_test/features/security_settings/presentation/cubit/security_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late SecurityCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final repo = SecurityRepositoryImpl(SecurityLocalDataSource());
    final session = RequireSession(auth);
    cubit = SecurityCubit(
      getSettings: GetSecuritySettings(session, repo),
      getPreferences: GetAppPreferences(session, repo),
      setBiometric: SetBiometricEnabled(session, repo),
      setWhitelisting: SetAddressWhitelisting(session, repo),
      logout: Logout(LockSession(auth)),
      requestDocument: RequestAccountDocument(session, repo),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits success', () async {
    await cubit.load();
    expect(cubit.state, isA<SecuritySuccess>());
    expect((cubit.state as SecuritySuccess).preferences.displayCurrency, 'USD');
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<SecurityFailure>());
  });
}
