import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/chart_sample.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/home/domain/entities/dashboard.dart';
import 'package:fintech_app_test/features/home/domain/repositories/home_repository.dart';
import 'package:fintech_app_test/features/home/domain/usecases/home_usecases.dart';
import 'package:fintech_app_test/features/home/presentation/cubit/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHomeRepository extends Mock implements HomeRepository {}

DashboardOverview _overview(DashboardPeriod period) {
  return DashboardOverview(
    netWorth: Money.parse('35862.41', Currency.usd),
    periodChangeRatio: Decimal.parse('-0.0492'),
    period: period,
    chart: [
      ChartSample(
        value: Money.parse('1', Currency.usd),
        at: DateTime.utc(2026, 1, 1),
      ),
      ChartSample(
        value: Money.parse('1.1', Currency.usd),
        at: DateTime.utc(2026, 1, 2),
      ),
    ],
    freshness: QuoteFreshness.stale,
    initials: '78',
  );
}

WatchlistItem _item(Currency currency) {
  return WatchlistItem(
    currency: currency,
    displayName: currency.code,
    price: Money.parse('1', Currency.usd),
    change24hRatio: Decimal.zero,
    sparkline: const [],
    freshness: QuoteFreshness.stale,
  );
}

void main() {
  late MockAuthRepository auth;
  late MockHomeRepository home;
  late HomeCubit cubit;

  setUpAll(() {
    registerFallbackValue(Currency.btc);
    registerFallbackValue(DashboardPeriod.oneWeek);
  });

  setUp(() {
    auth = MockAuthRepository();
    home = MockHomeRepository();
    final requireSession = RequireSession(auth);
    cubit = HomeCubit(
      getOverview: GetDashboardOverview(requireSession, home),
      getHoldings: GetHoldings(requireSession, home),
      getWatchlist: GetWatchlist(requireSession, home),
      getWatchlistCandidates: GetWatchlistCandidates(requireSession, home),
      searchWatchlistCandidates: SearchWatchlistCandidates(
        requireSession,
        home,
      ),
      addWatchlistItem: AddWatchlistItem(requireSession, home),
      getAlerts: GetDashboardAlerts(requireSession, home),
      dismissAlert: DismissDashboardAlert(requireSession, home),
      getPromos: GetDashboardPromos(requireSession, home),
      getNews: GetNewsPreview(requireSession, home),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    when(
      () => home.getOverview(
        initials: any(named: 'initials'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((invocation) async {
      final period =
          invocation.namedArguments[#period] as DashboardPeriod? ??
          DashboardPeriod.oneWeek;
      return Either.right(_overview(period));
    });
    when(() => home.getWatchlist()).thenAnswer((_) async => Either.right([]));
    when(() => home.getHoldings(any())).thenAnswer((_) async => Either.right([]));
    when(
      () => home.getWatchlistCandidates(),
    ).thenAnswer((_) async => Either.right([_item(Currency.sol)]));
    when(() => home.getAlerts()).thenAnswer((_) async => Either.right([]));
    when(() => home.getPromos()).thenAnswer((_) async => Either.right([]));
    when(() => home.getNewsPreview()).thenAnswer((_) async => Either.right([]));
  });

  tearDown(() => cubit.close());

  test('load emits success with holdings from the use case', () async {
    when(() => home.getHoldings(any())).thenAnswer(
      (_) async => Either.right([
        HoldingItem(
          currency: Currency.btc,
          displayName: 'Bitcoin',
          quantity: Money.parse('0.15', Currency.btc),
          value: Money.parse('11834.87', Currency.usd),
          change24hRatio: Decimal.zero,
          sparkline: const [],
          freshness: QuoteFreshness.stale,
        ),
      ]),
    );
    await cubit.load();
    expect(cubit.state, isA<HomeSuccess>());
    expect((cubit.state as HomeSuccess).overview.initials, '78');
    expect((cubit.state as HomeSuccess).holdings.single.currency, Currency.btc);
  });

  test('load emits failure without session', () async {
    when(
      () => auth.restoreSession(),
    ).thenAnswer((_) async => Either.left(const SessionFailure()));
    await cubit.load();
    expect(cubit.state, isA<HomeFailure>());
  });

  test('selectPeriod updates overview without emitting loading', () async {
    await cubit.load();
    clearInteractions(home);
    final emitted = <HomeState>[];
    final sub = cubit.stream.listen(emitted.add);

    await cubit.selectPeriod(DashboardPeriod.oneDay);

    expect(emitted.whereType<HomeLoading>(), isEmpty);
    expect(cubit.state, isA<HomeSuccess>());
    expect(
      (cubit.state as HomeSuccess).overview.period,
      DashboardPeriod.oneDay,
    );
    verifyNever(() => home.getWatchlist());
    verifyNever(() => home.getWatchlistCandidates());
    verify(
      () => home.getOverview(initials: '78', period: DashboardPeriod.oneDay),
    ).called(1);
    verify(() => home.getHoldings(DashboardPeriod.oneDay)).called(1);
    await sub.cancel();
  });

  test('addWatchlistItem appends without leaving success', () async {
    when(() => home.addWatchlistItem(Currency.sol)).thenAnswer(
      (_) async => Either.right([_item(Currency.btc), _item(Currency.sol)]),
    );
    when(
      () => home.searchWatchlistCandidates(any()),
    ).thenAnswer((_) async => Either.right([]));

    await cubit.load();
    expect(await cubit.addWatchlistItem(Currency.sol), Either.right(unit));

    expect(cubit.state, isA<HomeSuccess>());
    expect((cubit.state as HomeSuccess).watchlist.map((i) => i.currency), [
      Currency.btc,
      Currency.sol,
    ]);
    expect((cubit.state as HomeSuccess).watchlistCandidates, isEmpty);
  });

  test('addWatchlistItem returns the use case failure when it refuses', () async {
    when(() => home.addWatchlistItem(Currency.sol)).thenAnswer(
      (_) async =>
          Either.left(const ValidationFailure('watchlist_already_contains')),
    );

    await cubit.load();
    expect(
      await cubit.addWatchlistItem(Currency.sol),
      Either<Failure, Unit>.left(
        const ValidationFailure('watchlist_already_contains'),
      ),
    );
    expect((cubit.state as HomeSuccess).watchlist, isEmpty);
  });

  test('searchWatchlistCandidates updates the visible candidates', () async {
    when(
      () => home.searchWatchlistCandidates('sol'),
    ).thenAnswer((_) async => Either.right([_item(Currency.sol)]));

    await cubit.load();
    await cubit.searchWatchlistCandidates('sol');

    final state = cubit.state as HomeSuccess;
    expect(state.watchlistQuery, 'sol');
    expect(state.watchlistCandidates.map((i) => i.currency), [Currency.sol]);
  });
}
