import 'package:flutter/material.dart';

import '../market/price_series.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

abstract final class ChartPeriodLabel {
  static String of(ChartPeriod period) {
    return switch (period) {
      ChartPeriod.oneDay => '1D',
      ChartPeriod.oneWeek => '1W',
      ChartPeriod.oneMonth => '1M',
      ChartPeriod.oneYear => '1Y',
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: [
        for (final period in ChartPeriod.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: Key('period_${period.name}'),
              label: Text(ChartPeriodLabel.of(period)),
              selected: selected == period,
              selectedColor: AppColors.surfaceMuted,
              labelStyle: AppTextStyles.secondary.copyWith(
                color: AppColors.textPrimary,
              ),
              onSelected: (_) => onSelected(period),
            ),
          ),
      ],
      ),
    );
  }
}
