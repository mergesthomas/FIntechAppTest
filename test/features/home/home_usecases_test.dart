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
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockAuthRepository auth;
  late MockHomeRepository home;
  late GetDashboardOverview getOverview;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(DashboardPeriod.oneWeek);
  });

  setUp(() {
    auth = MockAuthRepository();
    home = MockHomeRepository();
    getOverview = GetDashboardOverview(RequireSession(auth), home);
  });

  test('refuses dashboard without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );

    final result = await getOverview(DashboardPeriod.oneWeek);

    expect(result.getLeft().toNullable(), isA<SessionFailure>());
    verifyNever(
      () => home.getOverview(
        initials: any(named: 'initials'),
        period: any(named: 'period'),
      ),
    );
  });

  test('loads overview when session exists', () async {
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

    final result = await getOverview(DashboardPeriod.oneWeek);

    expect(result.getRight().toNullable()?.initials, '78');
    expect(result.getRight().toNullable()?.freshness, QuoteFreshness.stale);
  });
}
