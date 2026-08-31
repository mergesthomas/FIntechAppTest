import '../../../../core/fixtures/news_feed_fixture.dart';
import '../../domain/entities/news_item.dart';

final class NewsLocalDataSource {
  const NewsLocalDataSource();

  List<NewsItem> feed() {
    return [
      for (final item in NewsFeedFixture.preview())
        NewsItem(
          id: item.id,
          source: item.source,
          headline: item.headline,
          age: item.age,
        ),
    ];
  }
}
