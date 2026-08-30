import 'package:decimal/decimal.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/explore_asset.dart';

final class ExploreLocalDataSource {
  const ExploreLocalDataSource();

  List<ExploreAsset> assets() {
    return [
      ExploreAsset(
        currency: Currency.btc,
        name: 'Bitcoin',
        price: Money.parse('78899.13', Currency.usd),
        change24h: Decimal.parse('0.0154'),
        freshness: QuoteFreshness.stale,
      ),
      ExploreAsset(
        currency: Currency.nexo,
        name: 'NEXO',
        price: Money.parse('0.8639', Currency.usd),
        change24h: Decimal.parse('0.0499'),
        freshness: QuoteFreshness.stale,
      ),
    ];
  }
}
