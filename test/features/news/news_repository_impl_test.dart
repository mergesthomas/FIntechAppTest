import 'package:fintech_app_test/core/fixtures/news_feed_fixture.dart';
import 'package:fintech_app_test/features/news/data/datasources/news_local_datasource.dart';
import 'package:fintech_app_test/features/news/data/repositories/news_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture feed is four Dogecoin stories, never more', () async {
    final repo = NewsRepositoryImpl(const NewsLocalDataSource());
    final feed = await repo.getFeed();
    final items = feed.getRight().toNullable();

    expect(items, isNotNull);
    expect(items, hasLength(NewsFeedFixture.maxItems));
    expect(items!.length, lessThanOrEqualTo(4));
    expect(
      items.every(
        (item) =>
            item.headline.contains('Dogecoin') ||
            item.headline.contains('DOGE'),
      ),
      isTrue,
    );
    expect(
      items.map((item) => item.headline),
      NewsFeedFixture.preview().map((item) => item.headline),
    );
  });
}
