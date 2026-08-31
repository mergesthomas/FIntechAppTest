import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/asset_list_row.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../domain/entities/explore_asset.dart';
import '../cubit/explore_cubit.dart';
import '../widgets/explore_sparkline.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _search = TextEditingController();
  var _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExploreCubit>().load();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _searching
            ? TextField(
                key: const Key('explore_search'),
                controller: _search,
                autofocus: true,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  hintText: 'Search assets',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: context.read<ExploreCubit>().search,
              )
            : const Text('Explore'),
        leading: context.canPop()
            ? const BackButton()
            : IconButton(
                tooltip: 'Profile',
                onPressed: () => context.push(AppRoute.profile.path),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.onSurface,
                  child: Text(
                    _initials(context),
                    style: AppTextStyles.meta.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
        actions: [
          IconButton(
            key: const Key('explore_search_toggle'),
            tooltip: 'Search',
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _search.clear();
                  context.read<ExploreCubit>().search('');
                }
              });
            },
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: BlocBuilder<ExploreCubit, ExploreState>(
        builder: (context, state) {
          return switch (state) {
            ExploreLoading() => const Center(child: CircularProgressIndicator()),
            ExploreEmpty() => const AppEmptyState(message: 'No assets'),
            ExploreFailure(:final failure) => AppEmptyState(message: '$failure'),
            ExploreSuccess() => _Feed(state: state),
          };
        },
      ),
    );
  }

  String _initials(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    if (session is! SessionSuccess) {
      return 'NA';
    }
    final digits = session.session.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) {
      return digits.substring(digits.length - 2);
    }
    return 'NA';
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.state});

  final ExploreSuccess state;

  @override
  Widget build(BuildContext context) {
    final feed = state.feed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        _Promo(promo: feed.promo),
        const AppSectionHeader('Top movers'),
        for (final asset in [...feed.gainers.take(3), ...feed.losers.take(3)])
          _assetRow(context, asset, keyed: false),
        const AppSectionHeader('Trending perpetuals'),
        for (final row in feed.perpetuals)
          AssetListRow(
            symbol: row.pair,
            subtitle: '${row.leverageTeaser} · ${row.freshness.name}',
            priceLabel: formatMoney(row.price),
            changeLabel: _pct(row.change24h),
            change: row.change24h,
            onTap: () => context.push(AppRoute.futures.path),
          ),
        const AppSectionHeader('Products'),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final tile in feed.products)
              TextButton(
                key: Key('explore_product_${tile.id}'),
                onPressed: () => _openProduct(context, tile.id),
                child: Text(tile.label),
              ),
          ],
        ),
        AppSectionHeader(
          'All assets',
          trailing: TextButton(
            onPressed: () => context.push(AppRoute.news.path),
            child: const Text('News'),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in ExploreAssetFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    key: Key('explore_filter_${filter.name}'),
                    label: Text(_filterLabel(filter)),
                    selected: state.filter == filter,
                    onSelected: (_) =>
                        context.read<ExploreCubit>().applyFilter(filter),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final asset in state.assets) _assetRow(context, asset),
      ],
    );
  }

  Widget _assetRow(
    BuildContext context,
    ExploreAsset asset, {
    bool keyed = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AssetListRow(
      key: keyed ? Key('explore_asset_${asset.currency.code}') : null,
      symbol: asset.currency.code,
      subtitle: '${asset.name} · ${asset.freshness.name}',
      priceLabel: formatMoney(asset.price),
      changeLabel: _pct(asset.change24h),
      change: asset.change24h,
      leadingTrail: ExploreSparkline(
        points: asset.sparkline,
        color: AppSemanticColors.change(
          scheme,
          up: asset.change24h >= Decimal.zero,
        ),
      ),
      onTap: () =>
          context.push('${AppRoute.market.path}/${asset.currency.code}'),
    );
  }

  void _openProduct(BuildContext context, String id) {
    final route = switch (id) {
      'futures' => AppRoute.futures,
      'card' => AppRoute.card,
      'more' => AppRoute.products,
      _ => null,
    };
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring Buy — screens missing')),
      );
      return;
    }
    context.push(route.path);
  }
}

class _Promo extends StatelessWidget {
  const _Promo({required this.promo});

  final ExplorePromo promo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promo.badge,
            style: AppTextStyles.meta.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(promo.body, style: AppTextStyles.body),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push(AppRoute.news.path),
              child: Text(promo.ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

String _filterLabel(ExploreAssetFilter filter) {
  return switch (filter) {
    ExploreAssetFilter.all => 'All assets',
    ExploreAssetFilter.gainers => 'Top gainers',
    ExploreAssetFilter.losers => 'Top losers',
    ExploreAssetFilter.newest => 'New assets',
  };
}

String _pct(Decimal change) {
  final value = (change * Decimal.fromInt(100)).toString();
  if (change > Decimal.zero) {
    return '+ $value%';
  }
  if (change < Decimal.zero) {
    return value.startsWith('-') ? '$value%' : '- $value%';
  }
  return '0.00%';
}
