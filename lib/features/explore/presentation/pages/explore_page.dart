import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _searching
            ? TextField(
                key: const Key('explore_search'),
                controller: _search,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search assets',
                  border: InputBorder.none,
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
                  backgroundColor: AppColors.surfaceMuted,
                  child: Text(_initials(context), style: AppTextStyles.secondary),
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
            ExploreEmpty() => const Center(child: Text('No assets')),
            ExploreFailure(:final failure) => Center(child: Text('$failure')),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Promo(promo: feed.promo),
        const SizedBox(height: 20),
        Text('Popular categories', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryCard(title: 'Top gainers', assets: feed.gainers),
              const SizedBox(width: 12),
              _CategoryCard(title: 'Top losers', assets: feed.losers),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Top earning assets', style: AppTextStyles.headline),
        Text(
          'APY teasers are placeholders',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final asset in feed.topEarning)
                _EarningCard(asset: asset),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final opportunity in feed.opportunities)
          _OpportunityTile(opportunity: opportunity),
        const SizedBox(height: 12),
        Text('Trending perpetuals', style: AppTextStyles.headline),
        for (final row in feed.perpetuals)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row.pair),
            subtitle: Text('${row.leverageTeaser} · ${row.freshness.name}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatMoney(row.price)),
                Text(
                  _pct(row.change24h),
                  style: TextStyle(color: _changeColor(row.change24h)),
                ),
              ],
            ),
            onTap: () => context.push(AppRoute.futures.path),
          ),
        const SizedBox(height: 8),
        Text('Products', style: AppTextStyles.headline),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tile in feed.products)
              ActionChip(
                key: Key('explore_product_${tile.id}'),
                label: Text(tile.label),
                onPressed: () => _openProduct(context, tile.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('All assets', style: AppTextStyles.headline),
            const Spacer(),
            TextButton(
              onPressed: () => context.push(AppRoute.news.path),
              child: const Text('News'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final filter in ExploreAssetFilter.values)
              FilterChip(
                key: Key('explore_filter_${filter.name}'),
                label: Text(_filterLabel(filter)),
                selected: state.filter == filter,
                onSelected: (_) =>
                    context.read<ExploreCubit>().applyFilter(filter),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final asset in state.assets)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(asset.currency.code),
            subtitle: Text('${asset.name} · ${asset.freshness.name}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExploreSparkline(
                  points: asset.sparkline,
                  color: _changeColor(asset.change24h),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatMoney(asset.price)),
                    Text(
                      _pct(asset.change24h),
                      style: TextStyle(color: _changeColor(asset.change24h)),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wallet / asset detail — blocked')),
            ),
          ),
      ],
    );
  }

  void _openProduct(BuildContext context, String id) {
    final route = switch (id) {
      'credit' => AppRoute.borrow,
      'savings' => AppRoute.earn,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(promo.badge, style: AppTextStyles.secondary),
          const SizedBox(height: 8),
          Text(promo.body, style: AppTextStyles.body),
          const SizedBox(height: 12),
          Text(promo.ctaLabel, style: const TextStyle(color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.title, required this.assets});

  final String title;
  final List<ExploreAsset> assets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.body),
          const SizedBox(height: 8),
          for (final asset in assets.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(asset.currency.code)),
                  Text(
                    _pct(asset.change24h),
                    style: TextStyle(color: _changeColor(asset.change24h)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  const _EarningCard({required this.asset});

  final ExploreEarningAsset asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(asset.currency.code, style: AppTextStyles.body),
          Text(
            _pct(asset.change24h),
            style: TextStyle(color: _changeColor(asset.change24h)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              asset.apyTeaser,
              style: const TextStyle(
                color: AppColors.onAccent,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityTile extends StatelessWidget {
  const _OpportunityTile({required this.opportunity});

  final ExploreOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(opportunity.title),
      subtitle: Text(opportunity.subtitleTeaser),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (opportunity.id == 'earn_nexo') {
          context.push(AppRoute.earn.path);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fixed Term — screens missing')),
        );
      },
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

Color _changeColor(Decimal change) {
  if (change < Decimal.zero) {
    return AppColors.danger;
  }
  return AppColors.accent;
}
