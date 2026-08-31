import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';

enum ExploreAssetFilter { all, gainers, losers, newest }

final class ExploreAsset extends Equatable {
  const ExploreAsset({
    required this.currency,
    required this.name,
    required this.price,
    required this.change24h,
    required this.freshness,
    this.isNew = false,
    this.sparkline = const [],
  });

  final Currency currency;
  final String name;
  final Money price;
  final Decimal change24h;
  final QuoteFreshness freshness;
  final bool isNew;
  final List<Decimal> sparkline;

  @override
  List<Object?> get props =>
      [currency, name, price, change24h, freshness, isNew, sparkline];
}

final class ExploreProductTile extends Equatable {
  const ExploreProductTile({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

final class ExplorePromo extends Equatable {
  const ExplorePromo({
    required this.badge,
    required this.body,
    required this.ctaLabel,
  });

  final String badge;
  final String body;
  final String ctaLabel;

  @override
  List<Object?> get props => [badge, body, ctaLabel];
}

final class ExploreFeed extends Equatable {
  const ExploreFeed({
    required this.promo,
    required this.gainers,
    required this.losers,
    required this.products,
    required this.assets,
  });

  final ExplorePromo promo;
  final List<ExploreAsset> gainers;
  final List<ExploreAsset> losers;
  final List<ExploreProductTile> products;
  final List<ExploreAsset> assets;

  @override
  List<Object?> get props => [
        promo,
        gainers,
        losers,
        products,
        assets,
      ];
}
