import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/price_series.dart';
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

  setUp(() {
    auth = MockAuthRepository();
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final session = RequireSession(auth);
    cubit = MarketCubit(
      getAsset: GetMarketAsset(session, repo),
      getChart: GetPriceChart(session, repo),
      code: 'BTC',
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits success', () async {
    await cubit.load();
    expect(cubit.state, isA<MarketSuccess>());
    expect(
      (cubit.state as MarketSuccess).asset.chart.closes.length,
      greaterThan(1),
    );
  });

  test('unknown asset emits failure', () async {
    final paper = PaperHarness();
    final repo = MarketRepositoryImpl(
      const MarketLocalDataSource(),
      feed: paper.feed,
    );
    final session = RequireSession(auth);
    final bad = MarketCubit(
      getAsset: GetMarketAsset(session, repo),
      getChart: GetPriceChart(session, repo),
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

  test('selectPeriod keeps the asset and changes the chart period', () async {
    await cubit.load();
    await cubit.selectPeriod(ChartPeriod.oneMonth);
    expect(cubit.state, isA<MarketSuccess>());
    expect(
      (cubit.state as MarketSuccess).asset.chart.period,
      ChartPeriod.oneMonth,
    );
  });
}
