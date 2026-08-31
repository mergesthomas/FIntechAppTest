import 'package:decimal/decimal.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/explore_asset.dart';

final class ExploreLocalDataSource {
  const ExploreLocalDataSource();

  static final _up = [
    Decimal.parse('0.98'),
    Decimal.parse('0.99'),
    Decimal.parse('1.01'),
    Decimal.parse('1.02'),
  ];
  static final _down = [
    Decimal.parse('1.02'),
    Decimal.parse('1.01'),
    Decimal.parse('0.99'),
    Decimal.parse('0.98'),
  ];

  ExploreAsset _asset({
    required Currency currency,
    required String name,
    required String price,
    required String change,
    bool isNew = false,
    required List<Decimal> sparkline,
  }) {
    return ExploreAsset(
      currency: currency,
      name: name,
      price: Money.parse(price, Currency.usd),
      change24h: Decimal.parse(change),
      freshness: QuoteFreshness.stale,
      isNew: isNew,
      sparkline: sparkline,
    );
  }

  List<ExploreAsset> assets() {
    return [
      _asset(
        currency: Currency.btc,
        name: 'Bitcoin',
        price: '78899.13',
        change: '0.0154',
        sparkline: _up,
      ),
      _asset(
        currency: Currency.eth,
        name: 'Ethereum',
        price: '2466.03',
        change: '0.0128',
        sparkline: _up,
      ),
      _asset(
        currency: Currency.usdt,
        name: 'Tether',
        price: '0.9999',
        change: '-0.0001',
        sparkline: _down,
      ),
      _asset(
        currency: Currency.xrp,
        name: 'XRP',
        price: '1.39',
        change: '0.0096',
        sparkline: _up,
      ),
      _asset(
        currency: Currency.nexo,
        name: 'NEXO',
        price: '0.8639',
        change: '0.0499',
        isNew: true,
        sparkline: _up,
      ),
      _asset(
        currency: Currency.doge,
        name: 'Dogecoin',
        price: '0.18',
        change: '-0.0210',
        sparkline: _down,
      ),
      _asset(
        currency: Currency.usdc,
        name: 'USDC',
        price: '1.00',
        change: '0.0000',
        sparkline: _up,
      ),
    ];
  }

  List<ExploreAsset> assetsFor(ExploreAssetFilter filter) {
    final all = assets();
    return switch (filter) {
      ExploreAssetFilter.all => all,
      ExploreAssetFilter.gainers =>
        all.where((a) => a.change24h > Decimal.zero).toList(),
      ExploreAssetFilter.losers =>
        all.where((a) => a.change24h < Decimal.zero).toList(),
      ExploreAssetFilter.newest => all.where((a) => a.isNew).toList(),
    };
  }

  List<ExploreAsset> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return assets();
    }
    return assets()
        .where(
          (a) =>
              a.currency.code.toLowerCase().contains(needle) ||
              a.name.toLowerCase().contains(needle),
        )
        .toList();
  }

  ExploreFeed feed() {
    final all = assets();
    return ExploreFeed(
      promo: const ExplorePromo(
        badge: 'For you',
        body:
            'Our EEA services continue uninterrupted. [placeholder — compliance review]',
        ctaLabel: 'Read more',
      ),
      gainers: all.where((a) => a.change24h > Decimal.zero).take(5).toList(),
      losers: all.where((a) => a.change24h < Decimal.zero).take(5).toList(),
      perpetuals: [
        ExplorePerpetual(
          pair: 'BTCUSDT',
          leverageTeaser: 'Up to 100x',
          price: Money.parse('78899.13', Currency.usdt),
          change24h: Decimal.parse('0.0130'),
          freshness: QuoteFreshness.stale,
        ),
        ExplorePerpetual(
          pair: 'ETHUSDT',
          leverageTeaser: 'Up to 100x',
          price: Money.parse('2466.03', Currency.usdt),
          change24h: Decimal.parse('0.0128'),
          freshness: QuoteFreshness.stale,
        ),
        ExplorePerpetual(
          pair: 'SOLUSDT',
          leverageTeaser: 'Up to 100x',
          price: Money.parse('148.20', Currency.usdt),
          change24h: Decimal.parse('0.0210'),
          freshness: QuoteFreshness.stale,
        ),
      ],
      products: const [
        ExploreProductTile(id: 'futures', label: 'Futures'),
        ExploreProductTile(id: 'card', label: 'Nexo Card'),
        ExploreProductTile(id: 'recurring', label: 'Recurring Buy'),
        ExploreProductTile(id: 'more', label: 'More'),
      ],
      assets: all,
    );
  }
}
