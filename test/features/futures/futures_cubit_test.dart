import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/futures/data/datasources/futures_local_datasource.dart';
import 'package:fintech_app_test/features/futures/data/repositories/futures_repository_impl.dart';
import 'package:fintech_app_test/features/futures/domain/usecases/futures_usecases.dart';
import 'package:fintech_app_test/features/futures/presentation/cubit/futures_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late FuturesCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    final paper = PaperHarness();
    final repo = FuturesRepositoryImpl(
      FuturesLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    final session = RequireSession(auth);
    final eligibility = GetEligibility(auth);
    final getQuote = GetFuturesQuote(session, eligibility, repo);
    cubit = FuturesCubit(
      getInstrument: GetFuturesInstrument(session, repo),
      getAccount: GetFuturesAccount(session, repo),
      getPositions: GetOpenPositions(session, repo),
      getTrades: GetLastTrades(session, repo),
      getDetails: GetPositionDetails(session, repo),
      previewPosition: PreviewFuturesPosition(getQuote),
      submit: SubmitFuturesOrder(session, eligibility, repo),
      setTpsl: SetTakeProfitStopLoss(session, eligibility, repo),
      close: ClosePosition(session, eligibility, repo),
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
    expect(cubit.state, isA<FuturesReady>());
    expect((cubit.state as FuturesReady).surface, FuturesSurface.ticket);
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<FuturesFailure>());
  });

  test('preview then confirm surfaces stale reject', () async {
    await cubit.load();
    await cubit.preview();
    expect((cubit.state as FuturesReady).surface, FuturesSurface.preview);
    await cubit.confirm(requestId: 'fut-1', stepUp: true);
    final ready = cubit.state as FuturesReady;
    expect(ready.surface, FuturesSurface.result);
    expect(ready.result, isA<StaleQuoteFailure>());
  });
}
