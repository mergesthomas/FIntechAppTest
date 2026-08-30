import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/pending_auth.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/sms_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late StartLogin startLogin;
  late VerifySmsCode verify;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    auth = MockAuthRepository();
    startLogin = StartLogin(auth);
    verify = VerifySmsCode(auth);
  });

  test('StartLogin rejects a short phone', () async {
    final result = await startLogin('123');

    expect(result, Either<Failure, PendingAuth>.left(const ValidationFailure('invalid_phone')));
    verifyNever(() => auth.startLogin(any()));
  });

  test('VerifySmsCode rejects a short code', () async {
    final result = await verify('12');

    expect(
      result,
      Either<Failure, Unit>.left(const ValidationFailure('sms_code_must_be_6_digits')),
    );
  });

  test('VerifySmsCode forwards a 6-digit code', () async {
    when(() => auth.verifySmsCode('123456')).thenAnswer(
      (_) async => Either.right(unit),
    );

    final result = await verify('123456');

    expect(result, Either<Failure, Unit>.right(unit));
  });
}
