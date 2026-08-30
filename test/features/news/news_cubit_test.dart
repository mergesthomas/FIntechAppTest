import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/news/data/datasources/news_local_datasource.dart';
import 'package:fintech_app_test/features/news/data/repositories/news_repository_impl.dart';
import 'package:fintech_app_test/features/news/domain/usecases/get_news_feed.dart';
import 'package:fintech_app_test/features/news/presentation/cubit/news_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;
  late NewsCubit cubit;

  setUp(() {
    auth = MockAuthRepository();
    cubit = NewsCubit(
      GetNewsFeed(
        RequireSession(auth),
        NewsRepositoryImpl(const NewsLocalDataSource()),
      ),
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
    expect(cubit.state, isA<NewsSuccess>());
  });

  test('load emits failure without session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    await cubit.load();
    expect(cubit.state, isA<NewsFailure>());
  });
}
