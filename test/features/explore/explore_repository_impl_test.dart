import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:fintech_app_test/features/explore/data/datasources/explore_local_datasource.dart';
import 'package:fintech_app_test/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:fintech_app_test/features/explore/domain/entities/explore_asset.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/paper_harness.dart';

void main() {
  test('fixture explore prices are stale, never live', () async {
    final paper = PaperHarness();
    final repo = ExploreRepositoryImpl(
      const ExploreLocalDataSource(),
      feed: paper.feed,
    );
    final feed = await repo.getFeed();
    final assets = await repo.getAssets(ExploreAssetFilter.all);
    expect(
      feed.getRight().toNullable()?.assets.every(
        (a) => a.freshness == QuoteFreshness.stale,
      ),
      isTrue,
    );
    expect(
      assets.getRight().toNullable()?.every(
        (a) => a.freshness == QuoteFreshness.stale,
      ),
      isTrue,
    );
    expect(
      assets.getRight().toNullable()?.every((a) => a.sparkline.length >= 2),
      isTrue,
    );
  });
}
