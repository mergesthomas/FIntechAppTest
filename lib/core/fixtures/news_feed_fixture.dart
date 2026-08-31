/// Local-only news seed shared by Home preview and the News feed.
/// Headlines are transcribed from public August 2026 reports. Not a live feed.
final class NewsFeedFixtureItem {
  const NewsFeedFixtureItem({
    required this.id,
    required this.headline,
    required this.source,
    required this.age,
  });

  final String id;
  final String headline;
  final String source;
  final String age;
}

abstract final class NewsFeedFixture {
  static const maxItems = 4;

  static const items = <NewsFeedFixtureItem>[
    NewsFeedFixtureItem(
      id: 'doge_august_gain',
      headline: 'Dogecoin logs strongest month of 2026 with a 21% August gain',
      source: 'TokenPost',
      age: '1h',
    ),
    NewsFeedFixtureItem(
      id: 'doge_sec_collectibles',
      headline:
          'SEC classifies meme coins as collectibles, clarifying Dogecoin\'s status',
      source: 'CoinMarketCap',
      age: '2d',
    ),
    NewsFeedFixtureItem(
      id: 'doge_etf_ftse',
      headline: '21Shares Dogecoin ETF switches to the FTSE pricing benchmark',
      source: '21Shares',
      age: '5d',
    ),
    NewsFeedFixtureItem(
      id: 'doge_etf_inflows',
      headline: 'Spot Dogecoin ETF inflows return as DOGE tests \$0.10',
      source: 'U.Today',
      age: '1w',
    ),
  ];

  static List<NewsFeedFixtureItem> preview() =>
      List<NewsFeedFixtureItem>.unmodifiable(items.take(maxItems));
}
