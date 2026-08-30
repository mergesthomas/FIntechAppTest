import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/market/price_series.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/period_chips.dart';
import '../../../../core/widgets/price_chart.dart';
import '../../../../core/widgets/trade_actions.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/dashboard.dart';
import '../copy/home_copy.dart';
import '../cubit/home_cubit.dart';
import '../../../explore/presentation/widgets/explore_sparkline.dart';

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
              HomeEmpty() => const Center(child: Text('No dashboard data')),
              HomeFailure(:final failure) => Center(child: Text('$failure')),
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
    return ListView(
      key: const Key('dashboard_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push(AppRoute.profile.path),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceMuted,
                child: Text(overview.initials, style: AppTextStyles.body),
              ),
            ),
            const Spacer(),
            Text('Nexo', style: AppTextStyles.headline),
            const Spacer(),
            IconButton(
              tooltip: 'Orders',
              onPressed: () => _go(context, AppRoute.orders),
              icon: const Icon(Icons.receipt_long_outlined),
            ),
            IconButton(
              tooltip: 'Rewards',
              onPressed: () => _soon(context, 'Rewards'),
              icon: const Icon(Icons.card_giftcard),
            ),
            IconButton(
              tooltip: 'Inbox',
              onPressed: () => _go(context, AppRoute.inbox),
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          formatMoney(overview.netWorth),
          key: const Key('net_worth'),
          style: AppTextStyles.title,
        ),
        const SizedBox(height: 4),
        Text(
          '${negative ? '' : '+'}${(change * Decimal.fromInt(100)).toString()}% · ${ChartPeriodLabel.of(chartPeriodOf(overview.period))} · ${overview.freshness.name}',
          style: AppTextStyles.secondary.copyWith(
            color: negative ? AppColors.danger : AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        TradeActions(
          onBuy: () => _go(context, AppRoute.funding, query: 'action=buy'),
          onExchange: () => _go(context, AppRoute.swap),
          onFutures: () => _go(context, AppRoute.futures),
          onAddFunds: () => _go(context, AppRoute.funding),
        ),
        const SizedBox(height: 16),
        _HubCard(
          key: const Key('credit_hub'),
          title: 'Credit Hub',
          value: formatMoney(state.credit.availableToBorrow),
          caption: 'Available to borrow',
          onTap: () => _go(context, AppRoute.borrow),
        ),
        const SizedBox(height: 12),
        _HubCard(
          key: const Key('savings_hub'),
          title: 'Savings Hub',
          value: formatMoney(state.savings.interestEarned),
          caption: 'Interest earned',
          onTap: () => _go(context, AppRoute.earn),
        ),
        const SizedBox(height: 16),
        PriceChart(points: overview.chart, height: 128),
        const SizedBox(height: 8),
        PeriodChips(
          selected: chartPeriodOf(overview.period),
          onSelected: (period) => context.read<HomeCubit>().selectPeriod(
                _dashboardPeriod(period),
              ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _soon(context, 'Wallet'),
            child: const Text('Wallet >'),
          ),
        ),
        for (final alert in state.alerts.where((a) => !a.dismissed)) ...[
          const SizedBox(height: 12),
          _AlertCard(
            text: HomeCopy.alert(alert.copyKey),
            onDismiss: () => context.read<HomeCubit>().dismiss(alert.id),
            onLearnMore: () => _go(context, AppRoute.funding),
          ),
        ],
        const SizedBox(height: 20),
        Text('Watchlist', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        for (final item in state.watchlist) _WatchlistRow(item: item),
        const SizedBox(height: 16),
        for (final promo in state.promos)
          _PromoCard(
            title: HomeCopy.promoTitle(promo.titleKey),
            body: HomeCopy.promoBody(promo.bodyKey),
            onTap: () => _go(context, AppRoute.borrow),
          ),
        const SizedBox(height: 16),
        Text('News', style: AppTextStyles.headline),
        for (final item in state.news)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(HomeCopy.newsTitle(item.titleKey)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _go(context, AppRoute.news),
          ),
        TextButton(
          onPressed: () => context.read<SessionCubit>().lock(),
          child: const Text('Lock session'),
        ),
      ],
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
      AppRoute.borrow,
      AppRoute.earn,
      AppRoute.card,
      AppRoute.swap,
      AppRoute.futures,
      AppRoute.orders,
      AppRoute.market,
    };
    if (ready.contains(route)) {
      context.push(query == null ? route.path : '${route.path}?$query');
      return;
    }
    _soon(context, route.path);
  }

  DashboardPeriod _dashboardPeriod(ChartPeriod period) {
    return switch (period) {
      ChartPeriod.oneDay => DashboardPeriod.oneDay,
      ChartPeriod.oneWeek => DashboardPeriod.oneWeek,
      ChartPeriod.oneMonth => DashboardPeriod.oneMonth,
      ChartPeriod.oneYear => DashboardPeriod.oneYear,
    };
  }

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — next feature')),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  final String title;
  final String value;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.secondary),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headline),
            Text(caption, style: AppTextStyles.secondary),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.text,
    required this.onDismiss,
    required this.onLearnMore,
  });

  final String text;
  final VoidCallback onDismiss;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(body),
      onTap: onTap,
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.item});

  final WatchlistItem item;

  @override
  Widget build(BuildContext context) {
    final up = item.change24hRatio >= Decimal.zero;
    return ListTile(
      key: Key('watchlist_${item.currency.code}'),
      contentPadding: EdgeInsets.zero,
      title: Text(item.currency.code),
      subtitle: Text('${item.displayName} · ${item.freshness.name}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExploreSparkline(
            points: item.sparkline,
            color: up ? AppColors.accent : AppColors.danger,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(formatMoney(item.price)),
              Text(
                '${up ? '+' : ''}${(item.change24hRatio * Decimal.fromInt(100)).toString()}%',
                style: TextStyle(color: up ? AppColors.accent : AppColors.danger),
              ),
            ],
          ),
        ],
      ),
      onTap: () => context.push('${AppRoute.market.path}/${item.currency.code}'),
    );
  }
}
