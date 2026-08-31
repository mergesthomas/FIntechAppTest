import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/error/failure.dart';
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

void main() {
  late MockAuthRepository auth;
  late MockHomeRepository home;
  late HomeCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    home = MockHomeRepository();
    final requireSession = RequireSession(auth);
    cubit = HomeCubit(
      getOverview: GetDashboardOverview(requireSession, home),
      getWatchlist: GetWatchlist(requireSession, home),
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
        initials: '78',
        period: DashboardPeriod.oneWeek,
      ),
    ).thenAnswer(
      (_) async => Either.right(
        DashboardOverview(
          netWorth: Money.parse('35862.41', Currency.usd),
          periodChangeRatio: Decimal.parse('-0.0492'),
          period: DashboardPeriod.oneWeek,
          chart: const [],
          freshness: QuoteFreshness.stale,
          initials: '78',
        ),
      ),
    );
    when(() => home.getWatchlist()).thenAnswer((_) async => Either.right([]));
    when(() => home.getAlerts()).thenAnswer((_) async => Either.right([]));
    when(() => home.getPromos()).thenAnswer((_) async => Either.right([]));
    when(() => home.getNewsPreview()).thenAnswer((_) async => Either.right([]));
  });

  tearDown(() => cubit.close());

  test('load emits success', () async {
    await cubit.load();
    expect(cubit.state, isA<HomeSuccess>());
    expect((cubit.state as HomeSuccess).overview.initials, '78');
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<HomeFailure>());
  });
}
