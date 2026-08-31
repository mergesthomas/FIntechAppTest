import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AssetListRow extends StatelessWidget {
  const AssetListRow({
    super.key,
    required this.symbol,
    required this.subtitle,
    required this.priceLabel,
    required this.changeLabel,
    required this.change,
    this.leadingTrail,
    this.onTap,
  });

  static const sparklineWidth = 64.0;
  static const quoteWidth = 112.0;

  final String symbol;
  final String subtitle;
  final String priceLabel;
  final String changeLabel;
  final Decimal change;
  final Widget? leadingTrail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final up = change >= Decimal.zero;
    final changeColor = AppSemanticColors.change(scheme, up: up);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol, style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.meta.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (leadingTrail != null) ...[
              SizedBox(
                width: sparklineWidth,
                height: 24,
                child: ClipRect(child: Center(child: leadingTrail)),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            SizedBox(
              width: quoteWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(priceLabel, style: AppTextStyles.numeric),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    changeLabel,
                    style: AppTextStyles.meta.copyWith(color: changeColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
