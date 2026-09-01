import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/ledger/paper_ledger.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/settlement/request_id.dart';
import 'package:fintech_app_test/core/settlement/settlement_status.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/orders/data/datasources/orders_local_datasource.dart';
import 'package:fintech_app_test/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:fintech_app_test/features/orders/domain/usecases/orders_usecases.dart';
import 'package:fintech_app_test/features/orders/presentation/cubit/open_orders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/paper_harness.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late PaperHarness paper;
  late OpenOrdersCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    paper = PaperHarness();
    final session = RequireSession(auth);
    final repo = OrdersRepositoryImpl(
      OrdersLocalDataSource(store: paper.store),
      ledger: paper.ledger,
    );
    cubit = OpenOrdersCubit(
      getOpen: GetOpenOrdersForAsset(session, repo),
      cancel: CancelOrder(session, GetEligibility(auth), repo),
      requestIds: ClockRequestIdFactory(),
      code: 'DOGE',
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load is empty when there is no resting order', () async {
    await cubit.load();
    expect(cubit.state, isA<OpenOrdersEmpty>());
  });

  test('cancel without step-up stays ready with a failure', () async {
    await paper.ledger.placeHold(
      requestId: 'hold-1',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
        id: 'ord-open',
        requestId: 'hold-1',
        pair: 'USDC/DOGE',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: Money.parse('10', Currency.usdc),
        wallet: 'savings',
        venue: PaperVenue.limit,
        pay: Currency.usdc,
        receive: Currency.doge,
      ),
    );
    await cubit.load();
    expect(cubit.state, isA<OpenOrdersReady>());
    final status = await cubit.cancel(orderId: 'ord-open', stepUp: false);
    expect(status, isNull);
    expect((cubit.state as OpenOrdersReady).failure, isA<StepUpFailure>());
  });

  test('cancel with step-up releases the hold', () async {
    await paper.ledger.placeHold(
      requestId: 'hold-1',
      hold: Money.parse('10', Currency.usdc),
      book: LedgerBook.savings,
      order: PaperOrder(
        id: 'ord-open',
        requestId: 'hold-1',
        pair: 'USDC/DOGE',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: Money.parse('10', Currency.usdc),
        wallet: 'savings',
        venue: PaperVenue.limit,
        pay: Currency.usdc,
        receive: Currency.doge,
      ),
    );
    await cubit.load();
    final status = await cubit.cancel(orderId: 'ord-open', stepUp: true);
    expect(status, SettlementStatus.confirmed);
    await cubit.load();
    expect(cubit.state, isA<OpenOrdersEmpty>());
  });
}
