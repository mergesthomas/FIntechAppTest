import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:fintech_app_test/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:fintech_app_test/features/profile/domain/usecases/profile_usecases.dart';
import 'package:fintech_app_test/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late ProfileCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final repo = ProfileRepositoryImpl(const ProfileLocalDataSource());
    final session = RequireSession(auth);
    cubit = ProfileCubit(
      getOverview: GetProfileOverview(session, repo),
      getRewards: GetRewardsTeasers(session, repo),
      getShortcuts: GetProfileProductShortcuts(session, repo),
      getVersion: GetAppVersionInfo(session, repo),
      getLegalLinks: GetLegalLinks(session, repo),
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
    expect(cubit.state, isA<ProfileSuccess>());
    expect((cubit.state as ProfileSuccess).version, '7.9.1');
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<ProfileFailure>());
  });
}
