import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
              MarketEmpty() => const Center(child: Text('No market data')),
              MarketFailure(:final failure) =>
                Center(child: Text('$failure')),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(asset.name, style: AppTextStyles.secondary),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                formatMoney(asset.price, withCode: true),
                key: const Key('market_price'),
                style: AppTextStyles.title,
              ),
            ),
            FreshnessChip(freshness: asset.freshness),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${up ? '+' : ''}${(asset.change24h * Decimal.fromInt(100)).toString()}%',
          style: AppTextStyles.secondary.copyWith(
            color: up ? AppColors.accent : AppColors.danger,
          ),
        ),
        const SizedBox(height: 16),
        PriceChart(
          key: const Key('market_chart'),
          points: asset.chart.closes,
        ),
        const SizedBox(height: 12),
        PeriodChips(
          selected: asset.chart.period,
          onSelected: context.read<MarketCubit>().selectPeriod,
        ),
        const SizedBox(height: 24),
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
