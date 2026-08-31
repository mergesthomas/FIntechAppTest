import 'package:fintech_app_test/core/fixtures/watchlist_catalog_fixture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog is 100 unique CMC-rank coins with BTC first', () {
    final coins = WatchlistCatalogFixture.coins;
    expect(coins, hasLength(WatchlistCatalogFixture.size));
    expect(coins.map((coin) => coin.code).toSet(), hasLength(coins.length));
    expect(
      coins.map((coin) => coin.rank),
      List.generate(coins.length, (i) => i + 1),
    );
    expect(coins.first.code, 'BTC');
    expect(coins.first.name, 'Bitcoin');
  });
}
