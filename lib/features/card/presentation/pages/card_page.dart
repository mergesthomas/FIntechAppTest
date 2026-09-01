import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/entities/card.dart';
import '../cubit/card_cubit.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CardCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: BlocBuilder<CardCubit, CardUiState>(
        builder: (context, state) {
          return switch (state) {
            CardLoading() => const Center(child: CircularProgressIndicator()),
            CardEmpty() => const AppEmptyState(message: 'No card'),
            CardFailure(:final failure) => AppEmptyState(
                message: '$failure',
                key: const Key('card_failure'),
              ),
            CardSuccess(:final snapshot) => _Body(snapshot: snapshot),
          };
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});

  final CardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final frozen = snapshot.status == CardStatus.frozen;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text(
          frozen ? 'Card frozen' : 'Card ${snapshot.status.name}',
          key: const Key('card_status'),
          style: AppTextStyles.secondary.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatMoney(snapshot.balances.eurx, withCode: true),
          style: AppTextStyles.balance,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '≈ ${formatMoney(snapshot.balances.usdApprox)}',
          style: AppTextStyles.secondary.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (frozen) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Swap to restore. Frozen is a first-class state.',
            style: AppTextStyles.secondary.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            key: const Key('restore_swap'),
            onPressed: () => _restore(context, RestoreRail.swap),
            child: const Text('Restore balance'),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextButton(
          key: const Key('unfreeze_card'),
          onPressed: () => context.read<CardCubit>().unfreeze(),
          child: const Text('Unfreeze'),
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context, RestoreRail rail) async {
    final result = await context.read<CardCubit>().restore(rail);
    if (!context.mounted) {
      return;
    }
    result.fold((_) {}, (chosen) {
      final route = switch (chosen) {
        RestoreRail.swap => AppRoute.swap,
      };
      context.push(route.path);
    });
  }
}
