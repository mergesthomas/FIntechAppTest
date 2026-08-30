import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/config/flavor_config.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fintech_app_test/features/auth/data/datasources/onboarding_local_datasource.dart';
import 'package:fintech_app_test/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySecureStore store;
  late MutableClock clock;
  late AuthRepositoryImpl repo;

  setUp(() {
    store = InMemorySecureStore();
    clock = MutableClock();
    repo = AuthRepositoryImpl(
      local: AuthLocalDataSource(store),
      onboarding: const OnboardingLocalDataSource(),
      flavor: FlavorConfig.dev,
      clock: clock,
      biometric: const AcceptingBiometricPort(),
    );
  });

  test('rejects a wrong SMS code and accepts the emulator code', () async {
    await repo.startSignUp('6912345678');
    final wrong = await repo.verifySmsCode('000000');
    expect(wrong.getLeft().toNullable(), isA<AuthFailure>());

    final ok = await repo.verifySmsCode('123456');
    expect(ok.isRight(), isTrue);
  });

  test('enforces resend cooldown then allows resend', () async {
    await repo.startLogin('6912345678');
    final early = await repo.resendSms();
    expect(early.getLeft().toNullable(), isA<AuthFailure>());

    clock.advance(const Duration(seconds: 31));
    final late = await repo.resendSms();
    expect(late.isRight(), isTrue);
  });

  test('confirm PIN mismatch then match, skip biometric opens a session', () async {
    await repo.startLogin('6912345678');
    await repo.verifySmsCode('123456');
    final draft = (await repo.createPin('2580')).getRight().toNullable()!;

    final mismatch = await repo.confirmPin(draft: draft, pin: '1111');
    expect(mismatch.getLeft().toNullable(), isA<AuthFailure>());

    final match = await repo.confirmPin(draft: draft, pin: '2580');
    expect(match.isRight(), isTrue);

    final session = await repo.skipBiometric();
    expect(session.getRight().toNullable()?.phone, '6912345678');

    final restored = await repo.restoreSession();
    expect(restored.isRight(), isTrue);
    expect(await store.read(AuthStoreKeys.sessionToken), isNotNull);
  });

  test('restoreSession fails when locked', () async {
    await repo.startLogin('6912345678');
    await repo.verifySmsCode('123456');
    final draft = (await repo.createPin('2580')).getRight().toNullable()!;
    await repo.confirmPin(draft: draft, pin: '2580');
    await repo.skipBiometric();
    await repo.lockSession();

    final restored = await repo.restoreSession();
    expect(restored.getLeft().toNullable(), isA<SessionFailure>());
  });
}
