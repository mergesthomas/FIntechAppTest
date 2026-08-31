import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/entities/product_tile.dart';
import '../cubit/products_cubit.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductsCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          return switch (state) {
            ProductsLoading() => const Center(child: CircularProgressIndicator()),
            ProductsEmpty() => const AppEmptyState(message: 'No products'),
            ProductsFailure(:final failure) => AppEmptyState(message: '$failure'),
            ProductsSuccess(:final tiles) => _Catalog(tiles: tiles),
          };
        },
      ),
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({required this.tiles});

  final List<ProductTile> tiles;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<ProductTile>>{};
    for (final tile in tiles) {
      groups.putIfAbsent(tile.group, () => []).add(tile);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        for (final entry in groups.entries) ...[
          AppSectionHeader(entry.key),
          for (final tile in entry.value)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tile.label),
              enabled: tile.enabled,
              trailing: tile.enabled
                  ? null
                  : Text(
                      'Unavailable',
                      style: AppTextStyles.meta.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
              onTap: tile.enabled ? () => _open(context, tile.id) : null,
            ),
        ],
      ],
    );
  }

  void _open(BuildContext context, String id) {
    final route = switch (id) {
      'explore' => AppRoute.explore,
      'news' => AppRoute.news,
      'card' => AppRoute.card,
      'swap' => AppRoute.swap,
      _ => null,
    };
    if (route == null) {
      return;
    }
    if (route == AppRoute.explore ||
        route == AppRoute.news ||
        route == AppRoute.funding ||
        route == AppRoute.card ||
        route == AppRoute.swap) {
      context.push(route.path);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${route.path} — next feature')),
    );
  }
}
