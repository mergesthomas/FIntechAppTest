import 'package:flutter/material.dart';

import '../../../../core/market/candle_series.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../copy/market_copy.dart';

class MarketOhlcBar extends StatelessWidget {
  const MarketOhlcBar({super.key, required this.candle});

  final OhlcvCandle candle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppSemanticColors.change(scheme, up: candle.isBullish);
    final style = AppTextStyles.meta.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final valueStyle = style.copyWith(color: color);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            const TextSpan(text: 'O '),
            TextSpan(text: formatMarketDecimal(candle.open), style: valueStyle),
            const TextSpan(text: '  H '),
            TextSpan(text: formatMarketDecimal(candle.high), style: valueStyle),
            const TextSpan(text: '  L '),
            TextSpan(text: formatMarketDecimal(candle.low), style: valueStyle),
            const TextSpan(text: '  C '),
            TextSpan(
              text: formatMarketDecimal(candle.close),
              style: valueStyle,
            ),
            TextSpan(text: '  ${MarketCopy.volume} '),
            TextSpan(
              text: formatMarketDecimal(candle.volume),
              style: valueStyle,
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
