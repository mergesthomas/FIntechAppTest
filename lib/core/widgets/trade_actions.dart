import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

abstract final class TradeActionLabels {
  static const buy = 'Buy';
  static const exchange = 'Exchange';
  static const futures = 'Futures';
  static const addFunds = 'Add funds';
}

class TradeActions extends StatelessWidget {
  const TradeActions({
    super.key,
    required this.onBuy,
    required this.onExchange,
    required this.onFutures,
    this.onAddFunds,
  });

  final VoidCallback onBuy;
  final VoidCallback onExchange;
  final VoidCallback onFutures;
  final VoidCallback? onAddFunds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
        _Action(
          key: const Key('trade_futures'),
          icon: Icons.show_chart,
          label: TradeActionLabels.futures,
          onTap: onFutures,
        ),
        if (onAddFunds != null)
          _Action(
            key: const Key('add_funds'),
            icon: Icons.account_balance_wallet_outlined,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surfaceMuted,
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.secondary),
          ],
        ),
      ),
    );
  }
}
