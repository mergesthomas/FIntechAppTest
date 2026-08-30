import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/earn/data/datasources/earn_local_datasource.dart';
import 'package:fintech_app_test/features/earn/data/repositories/earn_repository_impl.dart';
import 'package:fintech_app_test/features/earn/domain/usecases/earn_usecases.dart';
import 'package:fintech_app_test/features/earn/presentation/cubit/earn_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late EarnCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final repo = EarnRepositoryImpl(EarnLocalDataSource());
    final session = RequireSession(auth);
    final eligibility = GetEligibility(auth);
    cubit = EarnCubit(
      getOverview: GetSavingsHubOverview(session, repo),
      getProducts: GetEarnProducts(session, repo),
      getPreference: GetEarnInNexoPreference(session, repo),
      setEarnInNexo: SetEarnInNexo(session, eligibility, repo),
      stopEarning: StopEarning(session, eligibility, repo),
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
    expect(cubit.state, isA<EarnSuccess>());
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<EarnFailure>());
  });
}
