import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_page_body.dart';
import '../../domain/entities/dashboard.dart';
import '../copy/home_copy.dart';
import '../cubit/home_cubit.dart';
import '../widgets/watchlist_asset_row.dart';

class AddWatchlistPage extends StatefulWidget {
  const AddWatchlistPage({super.key});

  @override
  State<AddWatchlistPage> createState() => _AddWatchlistPageState();
}

class _AddWatchlistPageState extends State<AddWatchlistPage> {
  final _search = TextEditingController();
  var _adding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<HomeCubit>().searchWatchlistCandidates('');
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
      key: const Key('add_watchlist_page'),
      appBar: AppBar(title: const Text(HomeCopy.addToWatchlist)),
      body: AppPageBody(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.xs,
          AppSpacing.pageHorizontal,
          AppSpacing.lg,
        ),
        child: Column(
          children: [
            TextField(
              key: const Key('watchlist_search'),
              controller: _search,
              style: AppTextStyles.body,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: HomeCopy.watchlistSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.card,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: AppRadii.card,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadii.card,
                  borderSide: BorderSide(color: scheme.outline),
                ),
              ),
              onChanged: context.read<HomeCubit>().searchWatchlistCandidates,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: BlocSelector<HomeCubit, HomeState, _AddWatchlistView>(
                selector: (state) {
                  if (state is! HomeSuccess) {
                    return const (candidates: <WatchlistItem>[], query: '');
                  }
                  return (
                    candidates: state.watchlistCandidates,
                    query: state.watchlistQuery,
                  );
                },
                builder: (context, view) {
                  if (view.candidates.isEmpty) {
                    return AppEmptyState(
                      message:
                          view.query.trim().isEmpty
                              ? HomeCopy.watchlistNoMoreAssets
                              : HomeCopy.watchlistNoMatches,
                    );
                  }
                  return ListView.builder(
                    key: const Key('watchlist_add_list'),
                    itemCount: view.candidates.length,
                    itemBuilder: (context, index) {
                      final item = view.candidates[index];
                      return WatchlistAssetRow(
                        key: Key('watchlist_add_${item.currency.code}'),
                        item: item,
                        onTap: _adding ? null : () => _add(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(WatchlistItem item) async {
    if (_adding) {
      return;
    }
    setState(() => _adding = true);
    final added = await context.read<HomeCubit>().addWatchlistItem(
      item.currency,
    );
    if (!mounted) {
      return;
    }
    if (added) {
      context.pop();
      return;
    }
    setState(() => _adding = false);
  }
}

typedef _AddWatchlistView = ({List<WatchlistItem> candidates, String query});
