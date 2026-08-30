import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/dashboard.dart';
import '../copy/home_copy.dart';
import '../cubit/home_cubit.dart';
import '../widgets/sparkline.dart';

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
          '${negative ? '' : '+'}${(change * Decimal.fromInt(100)).toString()}% · 1W · ${overview.freshness.name}',
          style: AppTextStyles.secondary.copyWith(
            color: negative ? AppColors.danger : AppColors.accent,
          ),
        ),
        const SizedBox(height: 12),
        Sparkline(points: overview.chart),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _soon(context, 'Wallet'),
            child: const Text('Wallet >'),
          ),
        ),
        const SizedBox(height: 8),
        _HubCard(
          title: 'Credit Hub',
          value: formatMoney(state.credit.availableToBorrow),
          caption: 'Available to borrow',
          onTap: () => _go(context, AppRoute.borrow),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Savings Hub',
          value: formatMoney(state.savings.interestEarned),
          caption: 'Interest earned',
          onTap: () => _go(context, AppRoute.earn),
        ),
        for (final alert in state.alerts.where((a) => !a.dismissed)) ...[
          const SizedBox(height: 12),
          _AlertCard(
            text: HomeCopy.alert(alert.copyKey),
            onDismiss: () => context.read<HomeCubit>().dismiss(alert.id),
            onLearnMore: () => _go(context, AppRoute.funding),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _soon(context, 'Send crypto'),
                child: const Text('Send crypto'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _go(context, AppRoute.funding),
                child: const Text('Add funds'),
              ),
            ),
          ],
        ),
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

  void _go(BuildContext context, AppRoute route) {
    const ready = {
      AppRoute.profile,
      AppRoute.products,
      AppRoute.security,
      AppRoute.inbox,
      AppRoute.news,
      AppRoute.explore,
    };
    if (ready.contains(route)) {
      context.push(route.path);
      return;
    }
    _soon(context, route.path);
  }

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — next feature')),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
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
      contentPadding: EdgeInsets.zero,
      title: Text(item.currency.code),
      subtitle: Text('${item.displayName} · ${item.freshness.name}'),
      trailing: Column(
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
    );
  }
}
