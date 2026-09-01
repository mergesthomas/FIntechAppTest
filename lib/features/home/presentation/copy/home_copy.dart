import '../../../../core/fixtures/news_feed_fixture.dart';

/// Screenshot / fixture copy. COMPLIANCE: APY and legal strings are placeholders.
abstract final class HomeCopy {
  static const alerts = {
    'home.alert.eurx_below_zero':
        'Your EURx balance is below zero. Swap or restore. [placeholder]',
  };

  static const promos = <String, String>{};

  static const watchlistTitle = 'Watchlist';
  static const holdingsTitle = 'Holdings';
  static const addToWatchlist = 'Add to watchlist';
  static const watchlistSearchHint = 'Search coins';
  static const watchlistNoMoreAssets = 'No more assets to add';
  static const watchlistNoMatches = 'No matching coins';

  static String alert(String key) => alerts[key] ?? key;
  static String promoTitle(String key) => promos[key] ?? key;
  static String promoBody(String key) => promos[key] ?? key;

  static String newsTitle(String key) {
    for (final item in NewsFeedFixture.items) {
      if (item.id == key) {
        return item.headline;
      }
    }
    return key;
  }
}
