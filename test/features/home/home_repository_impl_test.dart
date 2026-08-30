import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/core/secure/secure_store.dart';
import 'package:fintech_app_test/features/home/data/datasources/home_local_datasource.dart';
import 'package:fintech_app_test/features/home/data/repositories/home_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture portfolio is stale, never live', () async {
    final repo = HomeRepositoryImpl(
      HomeLocalDataSource(InMemorySecureStore()),
    );

    final overview = await repo.getOverview(initials: '78');
    final watchlist = await repo.getWatchlist();

    expect(overview.getRight().toNullable()?.freshness, QuoteFreshness.stale);
    expect(
      watchlist.getRight().toNullable()?.every((i) => i.freshness == QuoteFreshness.stale),
      isTrue,
    );
  });
}
