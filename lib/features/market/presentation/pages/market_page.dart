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
import '../../../../core/widgets/trade_actions.dart';
import '../../domain/entities/market_asset.dart';
import '../copy/market_copy.dart';
import '../cubit/market_cubit.dart';
import '../widgets/market_candlestick_chart.dart';
import '../widgets/market_interval_chips.dart';
import '../widgets/market_ohlc_bar.dart';

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
              MarketSuccess() => _Body(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.state});

  final MarketSuccess state;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _chartKey = GlobalKey<MarketCandlestickChartState>();

  MarketAsset get asset => widget.state.asset;
  MarketSuccess get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final up = asset.change24h >= Decimal.zero;
    final scheme = Theme.of(context).colorScheme;
    final latest = state.candles.latest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.md,
            AppSpacing.pageHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.name,
                style: AppTextStyles.secondary.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMoney(asset.price, withCode: true),
                      key: const Key('market_price'),
                      style: AppTextStyles.balance,
                    ),
                  ),
                  FreshnessChip(freshness: asset.freshness),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${up ? '+' : ''}${(asset.change24h * Decimal.fromInt(100)).toString()}%',
                style: AppTextStyles.secondary.copyWith(
                  color: AppSemanticColors.change(scheme, up: up),
                ),
              ),
              if (latest != null) ...[
                const SizedBox(height: AppSpacing.xs),
                MarketOhlcBar(
                  key: const Key('market_ohlc_stats'),
                  candle: latest,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: KeyedSubtree(
              key: const Key('market_candlestick_chart'),
              child: MarketCandlestickChart(
                key: _chartKey,
                series: state.candles,
                showVolume: state.showVolume,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.xs,
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              MarketIntervalChips(
                selected: state.candles.interval,
                onSelected: context.read<MarketCubit>().selectInterval,
              ),
              const SizedBox(height: AppSpacing.xxs),
              _ChartToolbar(
                showVolume: state.showVolume,
                onReset: () => _chartKey.currentState?.resetZoom(),
              ),
              const SizedBox(height: AppSpacing.md),
              TradeActions(
                onBuy: () => context.push(
                  '${AppRoute.funding.path}?action=buy&asset=${asset.currency.code}',
                ),
                onExchange: () => context.push(AppRoute.swap.path),
                onFutures: () => context.push(AppRoute.futures.path),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartToolbar extends StatelessWidget {
  const _ChartToolbar({
    required this.showVolume,
    required this.onReset,
  });

  final bool showVolume;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        TextButton(
          key: const Key('market_volume_toggle'),
          onPressed: context.read<MarketCubit>().toggleVolume,
          child: Text(
            MarketCopy.volume,
            style: AppTextStyles.meta.copyWith(
              color: showVolume ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: showVolume ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          key: const Key('market_zoom_reset'),
          onPressed: onReset,
          child: Text(
            MarketCopy.resetZoom,
            style: AppTextStyles.meta.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
