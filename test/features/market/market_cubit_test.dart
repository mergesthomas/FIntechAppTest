import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/candle_interval.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/market/data/datasources/market_local_datasource.dart';
import 'package:fintech_app_test/features/market/data/repositories/market_repository_impl.dart';
import 'package:fintech_app_test/features/market/domain/usecases/market_usecases.dart';
import 'package:fintech_app_test/features/market/presentation/cubit/market_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late MarketCubit cubit;
  late PaperHarness paper;

  setUp(() {
    auth = MockAuthRepository();
    paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final session = RequireSession(auth);
    cubit = MarketCubit(
      getAsset: GetMarketAsset(session, repo),
      getCandles: GetCandleChart(session, repo),
      watchTicks: WatchMarketTicks(session, repo),
      code: 'BTC',
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits success with candles', () async {
    await cubit.load();
    expect(cubit.state, isA<MarketSuccess>());
    final success = cubit.state as MarketSuccess;
    expect(success.asset.chart.closes.length, greaterThan(1));
    expect(success.candles.candles.length, greaterThan(1));
    expect(success.candles.interval, CandleInterval.m15);
    expect(success.showVolume, isTrue);
  });

  test('unknown asset emits failure', () async {
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final session = RequireSession(auth);
    final bad = MarketCubit(
      getAsset: GetMarketAsset(session, repo),
      getCandles: GetCandleChart(session, repo),
      watchTicks: WatchMarketTicks(session, repo),
      code: 'NOPE',
    );
    await bad.load();
    expect(bad.state, isA<MarketFailure>());
    expect(
      (bad.state as MarketFailure).failure,
      isA<ValidationFailure>(),
    );
    await bad.close();
  });

  test('selectInterval keeps the asset and changes candles', () async {
    await cubit.load();
    await cubit.selectInterval(CandleInterval.h1);
    expect(cubit.state, isA<MarketSuccess>());
    expect(
      (cubit.state as MarketSuccess).candles.interval,
      CandleInterval.h1,
    );
    expect(
      (cubit.state as MarketSuccess).asset.chart.period,
      ChartPeriod.oneDay,
    );
  });

  test('toggleVolume flips the volume flag', () async {
    await cubit.load();
    cubit.toggleVolume();
    expect((cubit.state as MarketSuccess).showVolume, isFalse);
    cubit.toggleVolume();
    expect((cubit.state as MarketSuccess).showVolume, isTrue);
  });

  test('live tick updates the forming candle close', () async {
    await cubit.load();
    paper.feed.put(
      paper.feed.quoteFor(Currency.btc)!.copyWith(
        price: Money.parse('80000', Currency.usdt),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final success = cubit.state as MarketSuccess;
    expect(success.candles.latest!.close, Decimal.parse('80000'));
    expect(success.asset.price.amount, Decimal.parse('80000'));
  });
}
