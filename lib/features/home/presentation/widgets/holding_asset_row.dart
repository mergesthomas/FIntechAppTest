import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/asset_list_row.dart';
import '../../../explore/presentation/widgets/explore_sparkline.dart';
import '../../domain/entities/dashboard.dart';

class HoldingAssetRow extends StatelessWidget {
  const HoldingAssetRow({super.key, required this.item, this.onTap});

  final HoldingItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AssetListRow(
      symbol: item.currency.code,
      subtitle: item.freshness.labeled(formatQuantity(item.quantity)),
      priceLabel: formatMoney(item.value),
      changeLabel: formatPercent(item.change24hRatio),
      change: item.change24hRatio,
      leadingTrail: ExploreSparkline(
        key: Key('holding_sparkline_${item.currency.code}'),
        points: item.sparkline,
        color: AppSemanticColors.change(
          scheme,
          up: item.change24hRatio >= Decimal.zero,
        ),
      ),
      onTap: onTap,
    );
  }
}
