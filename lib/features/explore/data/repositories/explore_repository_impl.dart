import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/price_series.dart';
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

  Future<ExploreAsset> _overlay(ExploreAsset asset) async {
    final tick = _feed.quoteFor(asset.currency);
    final usd = _feed.usdPrice(asset.currency);
    final series = await _feed.refreshSeries(
      asset.currency,
      ChartPeriod.oneDay,
    );
    return ExploreAsset(
      currency: asset.currency,
      name: asset.name,
      price: usd ?? asset.price,
      change24h: tick?.change24h ?? asset.change24h,
      freshness: tick?.freshness ?? asset.freshness,
      isNew: asset.isNew,
      sparkline: series.closes,
    );
  }

  Future<ExploreFeed> _overlayFeed(ExploreFeed feed) async {
    final gainers = await Future.wait(feed.gainers.map(_overlay));
    final losers = await Future.wait(feed.losers.map(_overlay));
    final assets = await Future.wait(feed.assets.map(_overlay));
    return ExploreFeed(
      promo: feed.promo,
      gainers: gainers,
      losers: losers,
      products: feed.products,
      assets: assets,
    );
  }

  @override
  Future<Either<Failure, ExploreFeed>> getFeed() async {
    return Either.right(await _overlayFeed(_local.feed()));
  }

  @override
  Future<Either<Failure, List<ExploreAsset>>> getAssets(
    ExploreAssetFilter filter,
  ) async {
    final assets = await Future.wait(
      _local.assetsFor(filter).map(_overlay),
    );
    return Either.right(assets);
  }

  @override
  Future<Either<Failure, List<ExploreAsset>>> searchAssets(String query) async {
    final assets = await Future.wait(_local.search(query).map(_overlay));
    return Either.right(assets);
  }
}
