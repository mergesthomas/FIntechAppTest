import 'package:flutter/material.dart';

import '../../../../core/market/candle_interval.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../copy/market_copy.dart';

class MarketIntervalChips extends StatelessWidget {
  const MarketIntervalChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CandleInterval selected;
  final ValueChanged<CandleInterval> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final interval in CandleInterval.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: TextButton(
                key: Key('candle_interval_${interval.name}'),
                onPressed: () => onSelected(interval),
                style: TextButton.styleFrom(
                  foregroundColor: selected == interval
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  backgroundColor: selected == interval
                      ? scheme.surfaceContainerHighest
                      : Colors.transparent,
                  minimumSize: const Size(44, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  textStyle: AppTextStyles.meta.copyWith(
                    fontWeight: selected == interval
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                child: Text(MarketCopy.intervalLabel(interval)),
              ),
            ),
        ],
      ),
    );
  }
}
