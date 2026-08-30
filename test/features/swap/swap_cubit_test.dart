import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/swap/data/datasources/swap_local_datasource.dart';
import 'package:fintech_app_test/features/swap/data/repositories/swap_repository_impl.dart';
import 'package:fintech_app_test/features/swap/domain/usecases/swap_usecases.dart';
import 'package:fintech_app_test/features/swap/presentation/cubit/swap_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late SwapCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final repo = SwapRepositoryImpl(SwapLocalDataSource());
    final session = RequireSession(auth);
    final eligibility = GetEligibility(auth);
    cubit = SwapCubit(
      getWallets: GetSwapWallets(session, repo),
      searchAssets: SearchSwapAssets(session, repo),
      getQuote: GetSwapQuote(session, eligibility, repo),
      submit: SubmitSwap(session, eligibility, repo),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits ticket', () async {
    await cubit.load();
    expect(cubit.state, isA<SwapReady>());
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<SwapFailure>());
  });
}
