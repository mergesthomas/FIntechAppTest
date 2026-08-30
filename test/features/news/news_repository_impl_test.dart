import 'package:fintech_app_test/features/news/data/datasources/news_local_datasource.dart';
import 'package:fintech_app_test/features/news/data/repositories/news_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture news is a placeholder headline', () async {
    final repo = NewsRepositoryImpl(const NewsLocalDataSource());
    final feed = await repo.getFeed();
    expect(feed.getRight().toNullable()?.first.headline, contains('placeholder'));
  });
}
