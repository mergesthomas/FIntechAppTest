import '../../../../core/auth/eligibility_status.dart';
import '../../domain/entities/product_tile.dart';

final class ProductsLocalDataSource {
  const ProductsLocalDataSource();

  List<ProductTile> catalog({required EligibilityStatus eligibility}) {
    final moneyMovingEnabled = eligibility == EligibilityStatus.approved;
    return [
      ProductTile(
        id: 'card',
        label: 'Card',
        group: 'Spend',
        enabled: moneyMovingEnabled,
      ),
      ProductTile(
        id: 'swap',
        label: 'Swap',
        group: 'Trade',
        enabled: moneyMovingEnabled,
      ),
      ProductTile(
        id: 'futures',
        label: 'Futures',
        group: 'Trade',
        enabled: moneyMovingEnabled,
      ),
      const ProductTile(
        id: 'explore',
        label: 'Explore',
        group: 'Information',
        enabled: true,
      ),
      const ProductTile(
        id: 'news',
        label: 'News',
        group: 'Information',
        enabled: true,
      ),
    ];
  }
}
