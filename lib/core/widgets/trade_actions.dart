import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

abstract final class TradeActionLabels {
  static const buy = 'Buy';
  static const exchange = 'Exchange';
  static const addFunds = 'Add funds';
}

class TradeActions extends StatelessWidget {
  const TradeActions({
    super.key,
    required this.onBuy,
    required this.onExchange,
    this.onAddFunds,
  });

  final VoidCallback onBuy;
  final VoidCallback onExchange;
  final VoidCallback? onAddFunds;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Action(
          key: const Key('trade_buy'),
          icon: Icons.add,
          label: TradeActionLabels.buy,
          onTap: onBuy,
        ),
        _Action(
          key: const Key('trade_exchange'),
          icon: Icons.swap_horiz,
          label: TradeActionLabels.exchange,
          onTap: onExchange,
        ),
        if (onAddFunds != null)
          _Action(
            key: const Key('add_funds'),
            icon: Icons.south_west,
            label: TradeActionLabels.addFunds,
            onTap: onAddFunds!,
          ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Icon(icon, size: 22, color: scheme.onSurface),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: AppTextStyles.meta.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
