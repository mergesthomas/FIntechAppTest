import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/futures/data/datasources/futures_local_datasource.dart';
import 'package:fintech_app_test/features/futures/data/repositories/futures_repository_impl.dart';
import 'package:fintech_app_test/features/futures/domain/entities/futures.dart';
import 'package:fintech_app_test/features/futures/domain/repositories/futures_repository.dart';
import 'package:fintech_app_test/features/futures/domain/usecases/futures_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFuturesRepository extends Mock implements FuturesRepository {}

void main() {
  late MockAuthRepository auth;
  late FuturesRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    auth = MockAuthRepository();
    final paper = PaperHarness();
    repo = FuturesRepositoryImpl(
      FuturesLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('instrument requires session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await GetFuturesInstrument(RequireSession(auth), repo)(
      const NoParams(),
    );
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('close is confirmed and idempotent', () async {
    final close = ClosePosition(RequireSession(auth), GetEligibility(auth), repo);
    final first = await close((
      requestId: 'close-1',
      positionId: 'pos-pepe',
      stepUp: true,
    ));
    final retry = await close((
      requestId: 'close-1',
      positionId: 'pos-pepe',
      stepUp: true,
    ));
    expect(first.getRight().toNullable(), SettlementStatus.confirmed);
    expect(retry.getRight().toNullable(), SettlementStatus.confirmed);
  });

  test('set TP/SL refuses a stale mark', () async {
    final mockRepo = MockFuturesRepository();
    when(() => mockRepo.getPositionDetails('pos-pepe')).thenAnswer(
      (_) async => Either.right(
        FuturesPositionDetails(
          position: FuturesPosition(
            id: 'pos-pepe',
            pair: '1000PEPEUSDT',
            side: FuturesSide.long,
            size: Money.parse('1000', Currency.pepe),
            leverageTeaser: '100x',
          ),
          pnl: Money.parse('-12.40', Currency.usdt),
          entry: Money.parse('0.00000850', Currency.usdt),
          mark: Money.parse('0.00000840', Currency.usdt),
          liquidation: Money.parse('0.00000100', Currency.usdt),
          lockedCollateral: Money.parse('10.00', Currency.usdt),
          maintenanceMargin: Money.parse('2.00', Currency.usdt),
          fundingTeaser: 'funding countdown placeholder',
          orderId: 'ord-pepe-1',
          markFreshness: QuoteFreshness.stale,
        ),
      ),
    );
    final result = await SetTakeProfitStopLoss(
      RequireSession(auth),
      GetEligibility(auth),
      mockRepo,
    )((
      requestId: 'tpsl-1',
      positionId: 'pos-pepe',
      stepUp: true,
    ));
    expect(result.getLeft().toNullable(), isA<StaleQuoteFailure>());
    verifyNever(
      () => mockRepo.setTakeProfitStopLoss(
        requestId: any(named: 'requestId'),
        positionId: any(named: 'positionId'),
      ),
    );
  });
}
