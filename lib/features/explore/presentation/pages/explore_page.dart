import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/explore_cubit.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: BlocBuilder<ExploreCubit, ExploreState>(
        builder: (context, state) {
          return switch (state) {
            ExploreLoading() => const Center(child: CircularProgressIndicator()),
            ExploreEmpty() => const Center(child: Text('No assets')),
            ExploreFailure(:final failure) => Center(child: Text('$failure')),
            ExploreSuccess(:final assets) => ListView(
                children: [
                  const ListTile(
                    title: Text('All assets · fixture prices are stale'),
                  ),
                  ListTile(
                    key: const Key('explore_perpetuals'),
                    title: const Text('Perpetuals'),
                    subtitle: const Text('Open futures ticket'),
                    onTap: () => context.push(AppRoute.futures.path),
                  ),
                  for (final asset in assets)
                    ListTile(
                      title: Text(asset.currency.code),
                      subtitle: Text('${asset.name} · ${asset.freshness.name}'),
                      trailing: Text(
                        '${formatMoney(asset.price)}  ${(asset.change24h * Decimal.fromInt(100)).toString()}%',
                        style: TextStyle(
                          color: asset.change24h >= Decimal.zero
                              ? AppColors.accent
                              : AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
          };
        },
      ),
    );
  }
}
