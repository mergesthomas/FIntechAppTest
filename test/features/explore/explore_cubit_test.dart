import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/explore/data/datasources/explore_local_datasource.dart';
import 'package:fintech_app_test/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:fintech_app_test/features/explore/domain/usecases/get_explore_feed.dart';
import 'package:fintech_app_test/features/explore/presentation/cubit/explore_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late ExploreCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    cubit = ExploreCubit(
      GetExploreFeed(
        RequireSession(auth),
        ExploreRepositoryImpl(const ExploreLocalDataSource()),
      ),
    );
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('load emits success with stale prices', () async {
    await cubit.load();
    expect(cubit.state, isA<ExploreSuccess>());
    expect(
      (cubit.state as ExploreSuccess).assets.every(
        (a) => a.freshness == QuoteFreshness.stale,
      ),
      isTrue,
    );
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<ExploreFailure>());
  });
}
