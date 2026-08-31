import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/freshness_chip.dart';
import '../../../../core/widgets/period_chips.dart';
import '../../../../core/widgets/price_chart.dart';
import '../../../../core/widgets/trade_actions.dart';
import '../../domain/entities/market_asset.dart';
import '../cubit/market_cubit.dart';

class MarketPage extends ConsumerStatefulWidget {
  const MarketPage({super.key, required this.code});

  final String code;

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(marketCubitProvider(widget.code)).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = ref.watch(marketCubitProvider(widget.code));
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.code)),
        body: BlocBuilder<MarketCubit, MarketState>(
          builder: (context, state) {
            return switch (state) {
              MarketLoading() =>
                const Center(child: CircularProgressIndicator()),
              MarketEmpty() => const AppEmptyState(message: 'No market data'),
              MarketFailure(:final failure) =>
                AppEmptyState(message: '$failure'),
              MarketSuccess(:final asset) => _Body(asset: asset),
            };
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.asset});

  final MarketAsset asset;

  @override
  Widget build(BuildContext context) {
    final up = asset.change24h >= Decimal.zero;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text(
          asset.name,
          style: AppTextStyles.secondary.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatMoney(asset.price, withCode: true),
          key: const Key('market_price'),
          style: AppTextStyles.balance,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(
              '${up ? '+' : ''}${(asset.change24h * Decimal.fromInt(100)).toString()}%',
              style: AppTextStyles.secondary.copyWith(
                color: AppSemanticColors.change(scheme, up: up),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            FreshnessChip(freshness: asset.freshness),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PriceChart(
          key: const Key('market_chart'),
          points: asset.chart.closes,
          height: 160,
        ),
        const SizedBox(height: AppSpacing.sm),
        PeriodChips(
          selected: asset.chart.period,
          onSelected: context.read<MarketCubit>().selectPeriod,
        ),
        const SizedBox(height: AppSpacing.xl),
        TradeActions(
          onBuy: () => context.push(
            '${AppRoute.funding.path}?action=buy&asset=${asset.currency.code}',
          ),
          onExchange: () => context.push(AppRoute.swap.path),
          onFutures: () => context.push(AppRoute.futures.path),
        ),
      ],
    );
  }
}
