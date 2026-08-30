import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_text_styles.dart';
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
            CardEmpty() => const Center(child: Text('No card')),
            CardFailure(:final failure) => Center(
                child: Text('$failure', key: const Key('card_failure')),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          frozen ? 'Card frozen' : 'Card ${snapshot.status.name}',
          key: const Key('card_status'),
          style: AppTextStyles.title,
        ),
        Text(
          '${formatMoney(snapshot.balances.eurx, withCode: true)} ≈ ${formatMoney(snapshot.balances.usdApprox)}',
        ),
        if (frozen) ...[
          const SizedBox(height: 12),
          const Text(
            'Add funds, transfer, or swap to restore. Frozen is a first-class state.',
            style: AppTextStyles.secondary,
          ),
          ElevatedButton(
            key: const Key('restore_funding'),
            onPressed: () => _restore(context, RestoreRail.funding),
            child: const Text('Restore balance'),
          ),
          TextButton(
            onPressed: () => _restore(context, RestoreRail.swap),
            child: const Text('Swap'),
          ),
        ],
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
        RestoreRail.funding => AppRoute.funding,
        RestoreRail.swap => AppRoute.swap,
      };
      context.push(route.path);
    });
  }
}
