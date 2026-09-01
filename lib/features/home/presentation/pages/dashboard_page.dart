import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/clock/chart_time_label.dart';
import '../../../../core/market/chart_sample.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/notice/notice_copy.dart';
import '../../../../core/notice/user_notice.dart';
import '../../../../core/notice/user_notice_cubit.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/app_header_action.dart';
import '../../../../core/widgets/app_page_body.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/freshness_chip.dart';
import '../../../../core/widgets/period_chips.dart';
import '../../../../core/widgets/price_chart.dart';
import '../../domain/entities/dashboard.dart';
import '../copy/home_copy.dart';
import '../cubit/home_cubit.dart';
import '../widgets/holding_asset_row.dart';
import '../widgets/watchlist_asset_row.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          buildWhen:
              (previous, current) =>
                  previous.runtimeType != current.runtimeType,
          builder: (context, state) {
            return switch (state) {
              HomeLoading() => const Center(child: CircularProgressIndicator()),
              HomeEmpty() => const AppEmptyState(message: 'No dashboard data'),
              HomeFailure(:final failure) => AppFailureView(
                failure: failure,
                onRetry: () => context.read<HomeCubit>().load(),
              ),
              HomeSuccess() => const _DashboardBody(),
            };
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
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
          const _DashboardHeader(),
          const SizedBox(height: AppSpacing.xl),
          const _PortfolioHero(),
          const _AlertList(),
          const _HoldingsSection(),
          const _WatchlistSection(),
          const _PromoList(),
          const _NewsList(),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        BlocSelector<HomeCubit, HomeState, String>(
          selector:
              (state) => state is HomeSuccess ? state.overview.initials : '',
          builder: (context, initials) {
            return GestureDetector(
              onTap: () => context.push(AppRoute.profile.path),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.surfaceContainerHighest,
                foregroundColor: scheme.onSurface,
                child: Text(
                  initials,
                  style: AppTextStyles.meta.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
        const Spacer(),
        AppHeaderAction(
          key: const Key('inbox'),
          tooltip: 'Inbox',
          onPressed: () => _go(context, AppRoute.inbox),
          icon: Icon(Icons.notifications_none, color: scheme.onSurface),
        ),
      ],
    );
  }
}

class _PortfolioHero extends StatefulWidget {
  const _PortfolioHero();

  @override
  State<_PortfolioHero> createState() => _PortfolioHeroState();
}

class _PortfolioHeroState extends State<_PortfolioHero> {
  ChartSample? _scrub;

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) {
        if (previous is! HomeSuccess || current is! HomeSuccess) {
          return false;
        }
        return previous.overview.period != current.overview.period;
      },
      listener: (context, state) {
        if (_scrub != null) {
          setState(() => _scrub = null);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _NetWorthLabel(),
          const SizedBox(height: AppSpacing.xxs),
          _NetWorthAmount(preview: _scrub?.value),
          const SizedBox(height: AppSpacing.xs),
          _PeriodChangeRow(previewAt: _scrub?.at),
          const SizedBox(height: AppSpacing.lg),
          _PortfolioChart(onScrub: (sample) => setState(() => _scrub = sample)),
          const SizedBox(height: AppSpacing.sm),
          const _PeriodSelector(),
        ],
      ),
    );
  }
}

class _NetWorthLabel extends StatelessWidget {
  const _NetWorthLabel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      'Net worth',
      style: AppTextStyles.secondary.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _NetWorthAmount extends StatelessWidget {
  const _NetWorthAmount({this.preview});

  final Money? preview;

  @override
  Widget build(BuildContext context) {
    if (preview != null) {
      return Text(
        formatMoney(preview!),
        key: const Key('net_worth'),
        style: AppTextStyles.balance,
      );
    }
    return BlocSelector<HomeCubit, HomeState, String>(
      selector:
          (state) =>
              state is HomeSuccess ? formatMoney(state.overview.netWorth) : '',
      builder: (context, label) {
        return Text(
          label,
          key: const Key('net_worth'),
          style: AppTextStyles.balance,
        );
      },
    );
  }
}

class _PeriodChangeRow extends StatelessWidget {
  const _PeriodChangeRow({this.previewAt});

  final DateTime? previewAt;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, _PeriodChangeView?>(
      selector: (state) {
        if (state is! HomeSuccess) {
          return null;
        }
        final overview = state.overview;
        return (
          ratio: overview.periodChangeRatio,
          period: overview.period,
          freshness: overview.freshness,
        );
      },
      builder: (context, view) {
        if (view == null) {
          return const SizedBox.shrink();
        }
        final scheme = Theme.of(context).colorScheme;
        if (previewAt != null) {
          return Text(
            chartTimeLabel(
              previewAt!,
              includeTime: view.period == DashboardPeriod.oneDay,
            ),
            key: const Key('chart_scrub_label'),
            style: AppTextStyles.secondary.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );
        }
        final negative = view.ratio < Decimal.zero;
        return Row(
          children: [
            Text(
              '${negative ? '' : '+'}${formatPercent(view.ratio, signed: false)} · ${ChartPeriodLabel.of(chartPeriodOf(view.period))}',
              style: AppTextStyles.secondary.copyWith(
                color: AppSemanticColors.change(scheme, up: !negative),
              ),
            ),
            if (view.freshness.statusLabel != null) ...[
              const SizedBox(width: AppSpacing.xs),
              FreshnessChip(freshness: view.freshness),
            ],
          ],
        );
      },
    );
  }
}

typedef _PeriodChangeView =
    ({Decimal ratio, DashboardPeriod period, QuoteFreshness freshness});

class _PortfolioChart extends StatelessWidget {
  const _PortfolioChart({this.onScrub});

  final ValueChanged<ChartSample?>? onScrub;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, List<ChartSample>>(
      selector:
          (state) => state is HomeSuccess ? state.overview.chart : const [],
      builder: (context, samples) {
        return PriceChart(
          key: const Key('portfolio_chart'),
          points: [for (final sample in samples) sample.value.amount],
          times: [for (final sample in samples) sample.at],
          height: 120,
          onScrub: onScrub == null
              ? null
              : (index) {
                  if (index == null ||
                      index < 0 ||
                      index >= samples.length) {
                    onScrub!(null);
                    return;
                  }
                  onScrub!(samples[index]);
                },
        );
      },
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, ChartPeriod>(
      selector:
          (state) =>
              state is HomeSuccess
                  ? chartPeriodOf(state.overview.period)
                  : ChartPeriod.oneWeek,
      builder: (context, selected) {
        return PeriodChips(
          selected: selected,
          onSelected:
              (period) => context.read<HomeCubit>().selectPeriod(
                _dashboardPeriod(period),
              ),
        );
      },
    );
  }
}

class _AlertList extends StatelessWidget {
  const _AlertList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, List<DashboardAlert>>(
      selector: (state) => state is HomeSuccess ? state.alerts : const [],
      builder: (context, alerts) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final alert in alerts.where((a) => !a.dismissed)) ...[
              const SizedBox(height: AppSpacing.lg),
              _AlertBanner(
                text: HomeCopy.alert(alert.copyKey),
                onDismiss: () async {
                  final failure = await context.read<HomeCubit>().dismiss(
                    alert.id,
                  );
                  if (failure != null && context.mounted) {
                    context.showFailureNotice(failure);
                  }
                },
                onLearnMore: () => _go(context, AppRoute.card),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HoldingsSection extends StatelessWidget {
  const _HoldingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSectionHeader(HomeCopy.holdingsTitle),
        BlocSelector<HomeCubit, HomeState, List<HoldingItem>>(
          selector:
              (state) => state is HomeSuccess ? state.holdings : const [],
          builder: (context, holdings) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in holdings)
                  HoldingAssetRow(
                    key: Key('holding_${item.currency.code}'),
                    item: item,
                    onTap:
                        () => context.push(
                          '${AppRoute.market.path}/${item.currency.code}',
                        ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WatchlistSection extends StatelessWidget {
  const _WatchlistSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(
          HomeCopy.watchlistTitle,
          trailing: IconButton(
            key: const Key('watchlist_add'),
            tooltip: HomeCopy.addToWatchlist,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => context.push(AppRoute.watchlistAdd.path),
            icon: const Icon(Icons.add),
          ),
        ),
        BlocSelector<HomeCubit, HomeState, List<WatchlistItem>>(
          selector:
              (state) => state is HomeSuccess ? state.watchlist : const [],
          builder: (context, watchlist) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in watchlist)
                  WatchlistAssetRow(
                    key: Key('watchlist_${item.currency.code}'),
                    item: item,
                    onTap:
                        () => context.push(
                          '${AppRoute.market.path}/${item.currency.code}',
                        ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PromoList extends StatelessWidget {
  const _PromoList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, List<DashboardPromo>>(
      selector: (state) => state is HomeSuccess ? state.promos : const [],
      builder: (context, promos) {
        if (promos.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            for (final promo in promos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(HomeCopy.promoTitle(promo.titleKey)),
                subtitle: Text(HomeCopy.promoBody(promo.bodyKey)),
                onTap: () => _go(context, AppRoute.news),
              ),
          ],
        );
      },
    );
  }
}

class _NewsList extends StatelessWidget {
  const _NewsList();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, List<NewsPreview>>(
      selector: (state) => state is HomeSuccess ? state.news : const [],
      builder: (context, news) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSectionHeader(
              'News',
              trailing: TextButton(
                key: const Key('news_all'),
                onPressed: () => _go(context, AppRoute.news),
                child: const Text('All'),
              ),
            ),
            for (final item in news)
              ListTile(
                key: Key('news_preview_${item.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(HomeCopy.newsTitle(item.titleKey)),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => _go(context, AppRoute.news),
              ),
          ],
        );
      },
    );
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
                TextButton(
                  onPressed: onLearnMore,
                  child: const Text('Learn more'),
                ),
                TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

DashboardPeriod _dashboardPeriod(ChartPeriod period) {
  return switch (period) {
    ChartPeriod.oneDay => DashboardPeriod.oneDay,
    ChartPeriod.oneWeek => DashboardPeriod.oneWeek,
    ChartPeriod.oneMonth => DashboardPeriod.oneMonth,
    ChartPeriod.oneYear => DashboardPeriod.oneYear,
    ChartPeriod.all => DashboardPeriod.all,
  };
}

void _go(BuildContext context, AppRoute route) {
  const ready = {
    AppRoute.profile,
    AppRoute.products,
    AppRoute.security,
    AppRoute.inbox,
    AppRoute.news,
    AppRoute.explore,
    AppRoute.card,
    AppRoute.swap,
    AppRoute.orders,
    AppRoute.market,
    AppRoute.watchlistAdd,
  };
  if (ready.contains(route)) {
    context.push(route.path);
    return;
  }
  context.showUserNotice(UserNotice.info(NoticeCopy.unavailable));
}
