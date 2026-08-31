import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/repositories/market_repository_impl.dart';
import 'package:fintech_app_test/features/market/domain/usecases/market_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late MarketRepositoryImpl repo;

  setUp(() {
    auth = MockAuthRepository();
    repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: PaperHarness().feed,
    );
  });

  test('refuses market without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final getAsset = GetMarketAsset(RequireSession(auth), repo);
    final result = await getAsset((
      currency: Currency.btc,
      period: ChartPeriod.oneDay,
    ));
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('loads market asset when session exists', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    final getAsset = GetMarketAsset(RequireSession(auth), repo);
    final result = await getAsset((
      currency: Currency.btc,
      period: ChartPeriod.oneDay,
    ));
    expect(result.getRight().toNullable()?.currency, Currency.btc);
  });

  test('GetCandleChart refuses without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final getCandles = GetCandleChart(RequireSession(auth), repo);
    final result = await getCandles((
      currency: Currency.btc,
      interval: CandleInterval.m15,
    ));
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('GetCandleChart loads OHLCV when session exists', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    final getCandles = GetCandleChart(RequireSession(auth), repo);
    final result = await getCandles((
      currency: Currency.btc,
      interval: CandleInterval.h1,
    ));
    final series = result.getRight().toNullable();
    expect(series?.interval, CandleInterval.h1);
    expect(series?.candles.length, greaterThan(1));
  });
}
