import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/money/currency.dart';
import 'package:fintech_app_test/core/money/money.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/explore/domain/entities/explore_asset.dart';
import 'package:fintech_app_test/features/explore/domain/repositories/explore_repository.dart';
import 'package:fintech_app_test/features/explore/domain/usecases/get_explore_feed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockExploreRepository extends Mock implements ExploreRepository {}

void main() {
  late MockAuthRepository auth;
  late MockExploreRepository explore;
  late GetExploreFeed getFeed;

  setUp(() {
    auth = MockAuthRepository();
    explore = MockExploreRepository();
    getFeed = GetExploreFeed(RequireSession(auth), explore);
  });

  test('refuses explore without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await getFeed(const NoParams());
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('loads assets when session exists', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    when(() => explore.getAssets()).thenAnswer(
      (_) async => Either.right([
        ExploreAsset(
          currency: Currency.btc,
          name: 'Bitcoin',
          price: Money.parse('78899.13', Currency.usd),
          change24h: Decimal.parse('0.0154'),
          freshness: QuoteFreshness.stale,
        ),
      ]),
    );

    final result = await getFeed(const NoParams());
    expect(result.getRight().toNullable()?.first.freshness, QuoteFreshness.stale);
  });
}
