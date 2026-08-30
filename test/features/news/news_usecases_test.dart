import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/usecase/use_case.dart';
import 'package:fintech_app_test/features/auth/domain/entities/session.dart';
import 'package:fintech_app_test/features/auth/domain/repositories/auth_repository.dart';
import 'package:fintech_app_test/features/auth/domain/usecases/session_usecases.dart';
import 'package:fintech_app_test/features/news/domain/entities/news_item.dart';
import 'package:fintech_app_test/features/news/domain/repositories/news_repository.dart';
import 'package:fintech_app_test/features/news/domain/usecases/get_news_feed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockNewsRepository extends Mock implements NewsRepository {}

void main() {
  late MockAuthRepository auth;
  late MockNewsRepository news;
  late GetNewsFeed getFeed;

  setUp(() {
    auth = MockAuthRepository();
    news = MockNewsRepository();
    getFeed = GetNewsFeed(RequireSession(auth), news);
  });

  test('refuses news without a session', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.left(const SessionFailure()),
    );
    final result = await getFeed(const NoParams());
    expect(result.getLeft().toNullable(), isA<SessionFailure>());
  });

  test('loads feed when session exists', () async {
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => Either.right(
        const Session(token: 't', phone: '6912345678', biometricEnabled: false),
      ),
    );
    when(() => news.getFeed()).thenAnswer(
      (_) async => Either.right(const [
        NewsItem(
          id: '1',
          source: 'Fixture',
          headline: 'Markets wrap — placeholder',
          age: '2h',
        ),
      ]),
    );

    final result = await getFeed(const NoParams());
    expect(result.getRight().toNullable()?.first.source, 'Fixture');
  });
}
