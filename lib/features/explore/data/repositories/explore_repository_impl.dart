import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/explore_asset.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_local_datasource.dart';

final class ExploreRepositoryImpl implements ExploreRepository {
  ExploreRepositoryImpl(
    this._local, {
    required MarketFeed feed,
  }) : _feed = feed;

  final ExploreLocalDataSource _local;
  final MarketFeed _feed;

  ExploreAsset _overlay(ExploreAsset asset) {
    final tick = _feed.quoteFor(asset.currency);
    final usd = _feed.usdPrice(asset.currency);
    return ExploreAsset(
      currency: asset.currency,
      name: asset.name,
      price: usd ?? asset.price,
      change24h: tick?.change24h ?? asset.change24h,
      freshness: tick?.freshness ?? asset.freshness,
      isNew: asset.isNew,
      sparkline: _feed.seriesFor(asset.currency).closes,
    );
  }

  ExploreFeed _overlayFeed(ExploreFeed feed) {
    return ExploreFeed(
      promo: feed.promo,
      gainers: feed.gainers.map(_overlay).toList(),
      losers: feed.losers.map(_overlay).toList(),
      topEarning: feed.topEarning,
      opportunities: feed.opportunities,
      perpetuals: [
        for (final row in feed.perpetuals)
          ExplorePerpetual(
            pair: row.pair,
            leverageTeaser: row.leverageTeaser,
            price: _feed.usdPrice(
                  row.pair.startsWith('ETH') ? Currency.eth : Currency.btc,
                ) ??
                row.price,
            change24h: row.change24h,
            freshness: _feed.connection,
          ),
      ],
      products: feed.products,
      assets: feed.assets.map(_overlay).toList(),
    );
  }

  @override
  Future<Either<Failure, ExploreFeed>> getFeed() async {
    return Either.right(_overlayFeed(_local.feed()));
  }

  @override
  Future<Either<Failure, List<ExploreAsset>>> getAssets(
    ExploreAssetFilter filter,
  ) async {
    return Either.right(_local.assetsFor(filter).map(_overlay).toList());
  }

  @override
  Future<Either<Failure, List<ExploreAsset>>> searchAssets(String query) async {
    return Either.right(_local.search(query).map(_overlay).toList());
  }
}
