import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/swap/data/datasources/swap_local_datasource.dart';
import 'package:fintech_app_test/features/swap/data/repositories/swap_repository_impl.dart';
import 'package:fintech_app_test/features/swap/domain/entities/swap.dart';
import 'package:fintech_app_test/features/swap/domain/usecases/swap_usecases.dart';
import 'package:fintech_app_test/features/swap/presentation/cubit/swap_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late SwapCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final paper = PaperHarness();
    final repo = SwapRepositoryImpl(
      SwapLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    final session = RequireSession(auth);
    final eligibility = GetEligibility(auth);
    cubit = SwapCubit(
      searchAssets: SearchSwapAssets(session, repo),
      getOrderTypes: GetSwapOrderTypes(session),
      watchRate: WatchSwapRate(session, repo),
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

  test('selectOrderType switches to limit', () async {
    await cubit.load();
    cubit.selectOrderType(SwapOrderType.limit);
    final ready = cubit.state as SwapReady;
    expect(ready.orderType, SwapOrderType.limit);
  });

  test('applyRouteSeed sets Limit without quoting', () async {
    await cubit.load();
    cubit.applyRouteSeed(
      toCode: 'BTC',
      quoteCode: 'USDT',
      type: 'limit',
      limitPrice: '78898.13',
    );
    final ready = cubit.state as SwapReady;
    expect(ready.orderType, SwapOrderType.limit);
    expect(ready.to.code, 'BTC');
    expect(ready.from.code, 'USDC');
    expect(ready.limitInput, '78898.13');
    expect(ready.quote, isNull);
    expect(ready.surface, SwapSurface.ticket);
  });
}
