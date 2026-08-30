import 'package:decimal/decimal.dart';
import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/explore/data/datasources/explore_local_datasource.dart';
import 'package:fintech_app_test/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:fintech_app_test/features/explore/domain/entities/explore_asset.dart';
import 'package:fintech_app_test/features/explore/domain/usecases/explore_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late ExploreRepositoryImpl repo;

  setUp(() {
    auth = MockAuthRepository();
    repo = ExploreRepositoryImpl(const ExploreLocalDataSource());
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  test('refuses explore without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await GetExploreFeed(RequireSession(auth), repo)(
      const NoParams(),
    );
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('loads a stale feed when session exists', () async {
    final result = await GetExploreFeed(RequireSession(auth), repo)(
      const NoParams(),
    );
    final feed = result.getRight().toNullable();
    expect(feed?.assets.every((a) => a.freshness == QuoteFreshness.stale), isTrue);
    expect(
      feed?.perpetuals.every((p) => p.freshness == QuoteFreshness.stale),
      isTrue,
    );
  });

  test('market filter returns only gainers', () async {
    final result = await GetMarketAssets(RequireSession(auth), repo)(
      ExploreAssetFilter.gainers,
    );
    final assets = result.getRight().toNullable()!;
    expect(assets, isNotEmpty);
    expect(assets.every((a) => a.change24h > Decimal.zero), isTrue);
  });

  test('search matches ticker or name', () async {
    final result = await SearchExploreAssets(RequireSession(auth), repo)('bit');
    expect(
      result.getRight().toNullable()?.every(
        (a) => a.name.toLowerCase().contains('bit'),
      ),
      isTrue,
    );
  });
}
