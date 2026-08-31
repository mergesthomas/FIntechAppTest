import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/market/price_series.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_page_body.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/asset_list_row.dart';
import '../../../../core/widgets/freshness_chip.dart';
import '../../../../core/widgets/period_chips.dart';
import '../../../../core/widgets/price_chart.dart';
import '../../../../core/widgets/trade_actions.dart';
import '../../../explore/presentation/widgets/explore_sparkline.dart';
import '../../domain/entities/dashboard.dart';
import '../copy/home_copy.dart';
import '../cubit/home_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return switch (state) {
              HomeLoading() => const Center(child: CircularProgressIndicator()),
              HomeEmpty() => const AppEmptyState(message: 'No dashboard data'),
              HomeFailure(:final failure) => AppEmptyState(message: '$failure'),
              HomeSuccess() => _DashboardBody(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state});

  final HomeSuccess state;

  @override
  Widget build(BuildContext context) {
    final overview = state.overview;
    final change = overview.periodChangeRatio;
    final negative = change < Decimal.zero;
    final scheme = Theme.of(context).colorScheme;
    return AppPageBody(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      child: ListView(
        key: const Key('dashboard_scroll'),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push(AppRoute.profile.path),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.onSurface,
                  child: Text(
                    overview.initials,
                    style: AppTextStyles.meta.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Inbox',
                onPressed: () => _go(context, AppRoute.inbox),
                icon: Icon(
                  Icons.notifications_none,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Net worth',
            style: AppTextStyles.secondary.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            formatMoney(overview.netWorth),
            key: const Key('net_worth'),
            style: AppTextStyles.balance,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                '${negative ? '' : '+'}${(change * Decimal.fromInt(100)).toString()}% · ${ChartPeriodLabel.of(chartPeriodOf(overview.period))}',
                style: AppTextStyles.secondary.copyWith(
                  color: AppSemanticColors.change(scheme, up: !negative),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              FreshnessChip(freshness: overview.freshness),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TradeActions(
            onBuy: () => _go(context, AppRoute.funding, query: 'action=buy'),
            onExchange: () => _go(context, AppRoute.swap),
            onAddFunds: () => _go(context, AppRoute.funding),
          ),
          const SizedBox(height: AppSpacing.lg),
          PriceChart(points: overview.chart, height: 120),
          const SizedBox(height: AppSpacing.sm),
          PeriodChips(
            selected: chartPeriodOf(overview.period),
            onSelected: (period) => context.read<HomeCubit>().selectPeriod(
                  _dashboardPeriod(period),
                ),
          ),
          for (final alert in state.alerts.where((a) => !a.dismissed)) ...[
            const SizedBox(height: AppSpacing.lg),
            _AlertBanner(
              text: HomeCopy.alert(alert.copyKey),
              onDismiss: () => context.read<HomeCubit>().dismiss(alert.id),
              onLearnMore: () => _go(context, AppRoute.funding),
            ),
          ],
          const AppSectionHeader('Watchlist'),
          for (final item in state.watchlist) _WatchlistRow(item: item),
          if (state.promos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final promo in state.promos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(HomeCopy.promoTitle(promo.titleKey)),
                subtitle: Text(HomeCopy.promoBody(promo.bodyKey)),
                onTap: () => _go(context, AppRoute.news),
              ),
          ],
          AppSectionHeader(
            'News',
            trailing: TextButton(
              onPressed: () => _go(context, AppRoute.news),
              child: const Text('All'),
            ),
          ),
          for (final item in state.news)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(HomeCopy.newsTitle(item.titleKey)),
              trailing: Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
              ),
              onTap: () => _go(context, AppRoute.news),
            ),
        ],
      ),
    );
  }

  void _go(BuildContext context, AppRoute route, {String? query}) {
    const ready = {
      AppRoute.profile,
      AppRoute.products,
      AppRoute.security,
      AppRoute.inbox,
      AppRoute.news,
      AppRoute.explore,
      AppRoute.funding,
      AppRoute.card,
      AppRoute.swap,
      AppRoute.orders,
      AppRoute.market,
    };
    if (ready.contains(route)) {
      context.push(query == null ? route.path : '${route.path}?$query');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${route.path} — next feature')),
    );
  }

  DashboardPeriod _dashboardPeriod(ChartPeriod period) {
    return switch (period) {
      ChartPeriod.oneDay => DashboardPeriod.oneDay,
      ChartPeriod.oneWeek => DashboardPeriod.oneWeek,
      ChartPeriod.oneMonth => DashboardPeriod.oneMonth,
      ChartPeriod.oneYear => DashboardPeriod.oneYear,
    };
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.text,
    required this.onDismiss,
    required this.onLearnMore,
  });

  final String text;
  final VoidCallback onDismiss;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.card,
        border: Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: AppTextStyles.body),
            Row(
              children: [
                TextButton(onPressed: onLearnMore, child: const Text('Learn more')),
                TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.item});

  final WatchlistItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AssetListRow(
      key: Key('watchlist_${item.currency.code}'),
      symbol: item.currency.code,
      subtitle: '${item.displayName} · ${item.freshness.name}',
      priceLabel: formatMoney(item.price),
      changeLabel:
          '${item.change24hRatio >= Decimal.zero ? '+' : ''}${(item.change24hRatio * Decimal.fromInt(100)).toString()}%',
      change: item.change24hRatio,
      leadingTrail: ExploreSparkline(
        points: item.sparkline,
        color: AppSemanticColors.change(
          scheme,
          up: item.change24hRatio >= Decimal.zero,
        ),
      ),
      onTap: () => context.push('${AppRoute.market.path}/${item.currency.code}'),
    );
  }
}
