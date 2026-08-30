import '../../domain/entities/news_item.dart';

final class NewsLocalDataSource {
  const NewsLocalDataSource();

  List<NewsItem> feed() {
    return const [
      NewsItem(
        id: '1',
        source: 'Fixture',
        headline: 'Markets wrap — placeholder',
        age: '2h',
      ),
    ];
  }
}
