import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/profile/domain/entities/profile.dart';
import 'package:fintech_app_test/features/profile/domain/repositories/profile_repository.dart';
import 'package:fintech_app_test/features/profile/domain/usecases/profile_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockAuthRepository auth;
  late MockProfileRepository profile;
  late GetProfileOverview getOverview;

  setUp(() {
    auth = MockAuthRepository();
    profile = MockProfileRepository();
    getOverview = GetProfileOverview(RequireSession(auth), profile);
  });

  test('refuses profile without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );

    final result = await getOverview(const NoParams());

    expect(result.getLeft().toNullable(), isA<SessionFailure>());
    verifyNever(() => profile.getOverview());
  });

  test('loads overview when session exists', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    when(() => profile.getOverview()).thenAnswer(
      (_) async => Either.right(
        const ProfileOverview(
          greeting: 'Hello',
          loyaltyTier: 'Platinum',
          isPrivate: false,
        ),
      ),
    );

    final result = await getOverview(const NoParams());

    expect(result.getRight().toNullable()?.loyaltyTier, 'Platinum');
  });
}
