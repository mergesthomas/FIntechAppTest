import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../market/price_series.dart';

abstract final class ChartPeriodLabel {
  static String of(ChartPeriod period) {
    return switch (period) {
      ChartPeriod.oneDay => '1D',
      ChartPeriod.oneWeek => '1W',
      ChartPeriod.oneMonth => '1M',
      ChartPeriod.oneYear => '1Y',
      ChartPeriod.all => 'ALL',
    };
  }
}

class PeriodChips extends StatelessWidget {
  const PeriodChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final period in ChartPeriod.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TextButton(
                key: Key('period_${period.name}'),
                onPressed: () => onSelected(period),
                style: TextButton.styleFrom(
                  foregroundColor: selected == period
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  backgroundColor: selected == period
                      ? scheme.surfaceContainerHighest
                      : Colors.transparent,
                  minimumSize: const Size(0, 36),
                  padding: EdgeInsets.zero,
                  textStyle: AppTextStyles.meta.copyWith(
                    fontWeight: selected == period
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                child: Text(ChartPeriodLabel.of(period)),
              ),
            ),
          ),
      ],
    );
  }
}
