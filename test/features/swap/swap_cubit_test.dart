import 'package:fintech_app_test/core/clock/app_clock.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/ledger/paper_order.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/settlement/request_id.dart';
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

  /// Seeded fixture buys share the store, so count only swap submits.
  List<PaperOrder> swapOrders(PaperHarness paper) {
    return paper.store.all
        .where((order) => order.requestId.startsWith('swap-'))
        .toList();
  }

  SwapCubit buildCubit(PaperHarness paper) {
    final repo = SwapRepositoryImpl(
      SwapLocalDataSource(),
      feed: paper.feed,
      ledger: paper.ledger,
    );
    final session = RequireSession(auth);
    final eligibility = GetEligibility(auth);
    return SwapCubit(
      searchAssets: SearchSwapAssets(session, repo),
      getOrderTypes: GetSwapOrderTypes(session),
      watchRate: WatchSwapRate(session, repo),
      getQuote: GetSwapQuote(session, eligibility, repo),
      submit: SubmitSwap(session, eligibility, repo),
      requestIds: ClockRequestIdFactory(clock: MutableClock()),
    );
  }

  setUp(() {
    auth = MockAuthRepository();
    cubit = buildCubit(PaperHarness());
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
    expect(ready.inputField, SwapInputField.payAmount);
  });

  test('applyRouteSeed selects Instant to the market asset', () async {
    await cubit.load();
    cubit.applyRouteSeed(toCode: 'BTC', type: 'instant');
    final ready = cubit.state as SwapReady;
    expect(ready.orderType, SwapOrderType.instant);
    expect(ready.to.code, 'BTC');
    expect(ready.from.code, 'USDC');
    expect(ready.quote, isNull);
  });

  test('preview without an amount stays on the ticket', () async {
    await cubit.load();
    await cubit.preview();
    final ready = cubit.state as SwapReady;
    expect(ready.surface, SwapSurface.ticket);
    expect(ready.ticketFailure, isA<ValidationFailure>());
  });

  test('ticket has no request id until preview forms the intent', () async {
    await cubit.load();
    expect((cubit.state as SwapReady).requestId, isNull);
    cubit.typeAmount('10');
    await cubit.preview();
    final ready = cubit.state as SwapReady;
    expect(ready.surface, SwapSurface.preview);
    expect(ready.requestId, isNotNull);
    expect(ready.submitting, isFalse);
  });

  test('confirm without a request id does not submit', () async {
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final fresh = buildCubit(paper);
    await fresh.load();
    await fresh.confirm(stepUp: true);
    expect(swapOrders(paper), isEmpty);
    await fresh.close();
  });

  test('a second confirm while submitting is ignored', () async {
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final fresh = buildCubit(paper);
    await fresh.load();
    fresh.typeAmount('10');
    await fresh.preview();

    final first = fresh.confirm(stepUp: true);
    final second = fresh.confirm(stepUp: true);
    await Future.wait([first, second]);

    expect(swapOrders(paper), hasLength(1));
    expect((fresh.state as SwapReady).submitting, isFalse);
    await fresh.close();
  });

  test('a retry reuses the same request id and does not double-apply', () async {
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final fresh = buildCubit(paper);
    await fresh.load();
    fresh.typeAmount('10');
    await fresh.preview();
    final requestId = (fresh.state as SwapReady).requestId;

    await fresh.confirm(stepUp: true);
    await fresh.confirm(stepUp: true);

    expect((fresh.state as SwapReady).requestId, requestId);
    expect(swapOrders(paper), hasLength(1));
    expect(swapOrders(paper).single.requestId, requestId);
    await fresh.close();
  });

  test('a new intent mints a new request id and places again', () async {
    final paper = PaperHarness(freshness: QuoteFreshness.live);
    final fresh = buildCubit(paper);
    await fresh.load();
    fresh.typeAmount('10');
    await fresh.preview();
    final first = (fresh.state as SwapReady).requestId;
    await fresh.confirm(stepUp: true);

    fresh.backToTicket();
    expect((fresh.state as SwapReady).requestId, isNull);

    fresh.typeAmount('10');
    await fresh.preview();
    final second = (fresh.state as SwapReady).requestId;
    expect(second, isNot(first));
    await fresh.confirm(stepUp: true);

    expect(swapOrders(paper), hasLength(2));
    await fresh.close();
  });
}
