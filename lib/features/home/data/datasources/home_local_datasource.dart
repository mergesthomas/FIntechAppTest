import 'package:decimal/decimal.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/secure/secure_store.dart';
import '../../domain/entities/dashboard.dart';

final class HomeLocalDataSource {
  HomeLocalDataSource(this._store);

  final SecureStore _store;
  static const _dismissedKey = 'home.alerts.dismissed';

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

  List<Decimal> chartFor(DashboardPeriod period) {
    return switch (period) {
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
      DashboardPeriod.oneYear => [
          Decimal.parse('0.80'),
          Decimal.parse('0.88'),
          Decimal.parse('0.92'),
          Decimal.parse('0.95'),
        ],
    };
  }

  List<WatchlistItem> watchlist() {
    WatchlistItem item({
      required Currency currency,
      required String name,
      required String price,
      required String change,
    }) {
      return WatchlistItem(
        currency: currency,
        displayName: name,
        price: Money.parse(price, Currency.usd),
        change24hRatio: Decimal.parse(change),
        sparkline: const [],
        freshness: QuoteFreshness.stale,
      );
    }

    return [
      item(currency: Currency.btc, name: 'Bitcoin', price: '78899.13', change: '0.0154'),
      item(currency: Currency.doge, name: 'Dogecoin', price: '0.18', change: '-0.0120'),
      item(currency: Currency.pepe, name: 'Pepe', price: '0.00001', change: '0.0320'),
      item(currency: Currency.bonk, name: 'Bonk', price: '0.00002', change: '-0.0080'),
      item(currency: Currency.eth, name: 'Ethereum', price: '2466.03', change: '0.0128'),
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
    final ids = await _dismissedIds()..add(id);
    await _store.write(_dismissedKey, ids.join(','));
  }

  List<DashboardPromo> promos() => const [];

  List<NewsPreview> news() {
    return const [
      NewsPreview(id: 'news_1', titleKey: 'home.news.placeholder'),
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
