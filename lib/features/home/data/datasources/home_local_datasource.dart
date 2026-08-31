import 'package:decimal/decimal.dart';

import '../../../../core/fixtures/news_feed_fixture.dart';
import '../../../../core/fixtures/watchlist_catalog_fixture.dart';
import '../../../../core/market/chart_sample.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/secure/secure_store.dart';
import '../../domain/entities/dashboard.dart';

final class HomeLocalDataSource {
  HomeLocalDataSource(this._store);

  final SecureStore _store;
  static const _dismissedKey = 'home.alerts.dismissed';
  static const _watchlistKey = 'home.watchlist.codes';
  static const _defaultWatchlistCodes = ['BTC', 'DOGE', 'PEPE', 'BONK', 'ETH'];

  /// Screenshot fixture. Prices are cached → [QuoteFreshness.stale].
  DashboardOverview overview({
    required String initials,
    DashboardPeriod period = DashboardPeriod.oneWeek,
  }) {
    return DashboardOverview(
      netWorth: Money.parse('35862.41', Currency.usd),
      periodChangeRatio: Decimal.parse('-0.0492'),
      period: period,
      chart: chartFor(period),
      freshness: QuoteFreshness.stale,
      initials: initials,
    );
  }

  List<ChartSample> chartFor(DashboardPeriod period) {
    final values = switch (period) {
      DashboardPeriod.oneDay => [
        Decimal.parse('0.98'),
        Decimal.parse('0.99'),
        Decimal.parse('1.00'),
        Decimal.parse('0.97'),
        Decimal.parse('0.96'),
      ],
      DashboardPeriod.oneWeek => [
        Decimal.parse('1.00'),
        Decimal.parse('0.96'),
        Decimal.parse('0.97'),
        Decimal.parse('0.94'),
        Decimal.parse('0.95'),
        Decimal.parse('0.93'),
        Decimal.parse('0.951'),
      ],
      DashboardPeriod.oneMonth => [
        Decimal.parse('1.04'),
        Decimal.parse('1.01'),
        Decimal.parse('0.99'),
        Decimal.parse('0.96'),
        Decimal.parse('0.95'),
      ],
      DashboardPeriod.oneYear || DashboardPeriod.all => [
        Decimal.parse('0.80'),
        Decimal.parse('0.88'),
        Decimal.parse('0.92'),
        Decimal.parse('0.95'),
      ],
    };
    final now = DateTime.utc(2026, 1, 1);
    return [
      for (var i = 0; i < values.length; i++)
        ChartSample(
          value: Money.fromDecimal(
            values[i] * Decimal.parse('35862.41'),
            Currency.usd,
          ),
          at: now.subtract(Duration(days: values.length - 1 - i)),
        ),
    ];
  }

  bool isWatchable(Currency currency) => _catalog.containsKey(currency.code);

  Future<List<WatchlistItem>> watchlist() async {
    return _itemsFor(await watchlistCodes());
  }

  Future<List<WatchlistItem>> watchlistCandidates() {
    return searchWatchlistCandidates('');
  }

  Future<List<WatchlistItem>> searchWatchlistCandidates(String query) async {
    final selected = (await watchlistCodes()).toSet();
    final needle = query.trim().toLowerCase();
    return [
      for (final item in _catalog.values)
        if (!selected.contains(item.currency.code) && _matches(item, needle))
          item,
    ];
  }

  Future<List<String>> watchlistCodes() async {
    final raw = await _store.read(_watchlistKey);
    if (raw == null || raw.isEmpty) {
      return List.of(_defaultWatchlistCodes);
    }
    return [
      for (final code in raw.split(','))
        if (code.isNotEmpty && _catalog.containsKey(code)) code,
    ];
  }

  Future<void> addWatchlistCode(String code) async {
    final codes = await watchlistCodes();
    if (codes.contains(code)) {
      return;
    }
    codes.add(code);
    await _store.write(_watchlistKey, codes.join(','));
  }

  List<WatchlistItem> _itemsFor(List<String> codes) {
    return [
      for (final code in codes)
        if (_catalog[code] != null) _catalog[code]!,
    ];
  }

  Future<List<DashboardAlert>> alerts() async {
    final dismissed = await _dismissedIds();
    return [
      DashboardAlert(
        id: 'eurx_below_zero',
        copyKey: 'home.alert.eurx_below_zero',
        dismissed: dismissed.contains('eurx_below_zero'),
      ),
    ];
  }

  Future<void> dismissAlert(String id) async {
    final ids =
        await _dismissedIds()
          ..add(id);
    await _store.write(_dismissedKey, ids.join(','));
  }

  List<DashboardPromo> promos() => const [];

  List<NewsPreview> news() {
    return [
      for (final item in NewsFeedFixture.preview())
        NewsPreview(id: item.id, titleKey: item.id),
    ];
  }

  Future<Set<String>> _dismissedIds() async {
    final raw = await _store.read(_dismissedKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    return raw.split(',').where((id) => id.isNotEmpty).toSet();
  }
}

bool _matches(WatchlistItem item, String needle) {
  if (needle.isEmpty) {
    return true;
  }
  return item.currency.code.toLowerCase().contains(needle) ||
      item.displayName.toLowerCase().contains(needle);
}

WatchlistItem _itemFrom(WatchlistCatalogCoin coin) {
  final price = Money.parse(coin.usdPrice, Currency.usd);
  return WatchlistItem(
    currency:
        Currency.tryParse(coin.code) ??
        Currency(code: coin.code, scale: coin.scale),
    displayName: coin.name,
    price: price,
    change24hRatio: Decimal.parse(coin.change24h),
    sparkline: syntheticCloses(
      last: price.amount,
      period: ChartPeriod.oneDay,
      seedKey: coin.code,
      changeRatio: Decimal.parse(coin.change24h),
    ),
    freshness: QuoteFreshness.stale,
  );
}

final _catalog = <String, WatchlistItem>{
  for (final coin in WatchlistCatalogFixture.coins) coin.code: _itemFrom(coin),
};
