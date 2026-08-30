import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_text_styles.dart';
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
            ProductsEmpty() => const Center(child: Text('No products')),
            ProductsFailure(:final failure) => Center(child: Text('$failure')),
            ProductsSuccess(:final tiles) => ListView(
                children: [
                  for (final tile in tiles)
                    ListTile(
                      title: Text(tile.label),
                      subtitle: Text(tile.group, style: AppTextStyles.secondary),
                      enabled: tile.enabled,
                      onTap: tile.enabled ? () => _open(context, tile.id) : null,
                    ),
                ],
              ),
          };
        },
      ),
    );
  }

  void _open(BuildContext context, String id) {
    final route = switch (id) {
      'explore' => AppRoute.explore,
      'news' => AppRoute.news,
      'savings' => AppRoute.earn,
      'credit' => AppRoute.borrow,
      'card' => AppRoute.card,
      'swap' => AppRoute.swap,
      'futures' => AppRoute.futures,
      _ => null,
    };
    if (route == null) {
      return;
    }
    if (route == AppRoute.explore || route == AppRoute.news) {
      context.push(route.path);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${route.path} — next feature')),
    );
  }
}
