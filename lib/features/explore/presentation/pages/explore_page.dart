import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/app_header_action.dart';
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
        leadingWidth: 56,
        leading: context.canPop()
            ? const BackButton()
            : Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AppHeaderAction(
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
              ),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          AppHeaderAction(
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
            ExploreFailure(:final failure) => AppFailureView(
              failure: failure,
              onRetry: context.read<ExploreCubit>().load,
            ),
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
        const AppSectionHeader('Top movers'),
        for (final asset in [...feed.gainers.take(3), ...feed.losers.take(3)])
          _assetRow(context, asset, keyed: false),
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
      subtitle: asset.freshness.labeled(asset.name),
      priceLabel: formatMoney(asset.price),
      changeLabel: formatPercent(asset.change24h),
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
}

String _filterLabel(ExploreAssetFilter filter) {
  return switch (filter) {
    ExploreAssetFilter.all => 'All assets',
    ExploreAssetFilter.gainers => 'Top gainers',
    ExploreAssetFilter.losers => 'Top losers',
    ExploreAssetFilter.newest => 'New assets',
  };
}
