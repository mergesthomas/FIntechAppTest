import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/step_up_pin_dialog.dart';
import '../../domain/entities/swap.dart';
import '../cubit/swap_cubit.dart';

class SwapPage extends StatefulWidget {
  const SwapPage({super.key});

  @override
  State<SwapPage> createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SwapCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange'),
        actions: [
          IconButton(
            tooltip: 'Orders',
            onPressed: () => context.push(AppRoute.orders.path),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: BlocBuilder<SwapCubit, SwapState>(
        builder: (context, state) {
          return switch (state) {
            SwapLoading() => const Center(child: CircularProgressIndicator()),
            SwapEmpty() => const Center(child: Text('No swap assets')),
            SwapFailure(:final failure) => Center(child: Text('$failure')),
            SwapReady() => switch (state.surface) {
                SwapSurface.ticket => _Ticket(state: state),
                SwapSurface.preview => _Preview(state: state),
                SwapSurface.result => _Result(state: state),
              },
          };
        },
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.state});

  final SwapReady state;

  @override
  Widget build(BuildContext context) {
    final from = state.assets.where((a) => a.currency == state.from);
    final to = state.assets.where((a) => a.currency == state.to);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<SwapWallet>(
          segments: [
            for (final wallet in state.wallets)
              ButtonSegment(value: wallet, label: Text(wallet.name)),
          ],
          selected: {state.wallet},
          onSelectionChanged: (value) =>
              context.read<SwapCubit>().selectWallet(value.first),
        ),
        const SizedBox(height: 16),
        _AssetCard(
          title: 'From',
          code: state.from.code,
          balance: from.isEmpty ? null : from.first.balance,
        ),
        Align(
          child: IconButton(
            key: const Key('swap_flip'),
            onPressed: context.read<SwapCubit>().flip,
            icon: const Icon(Icons.swap_vert),
          ),
        ),
        _AssetCard(
          title: 'To',
          code: state.to.code,
          balance: to.isEmpty ? null : to.first.balance,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('swap_amount'),
          decoration: const InputDecoration(labelText: 'From amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: context.read<SwapCubit>().typeAmount,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('swap_preview'),
          onPressed: () => context.read<SwapCubit>().preview(),
          child: const Text('Preview order'),
        ),
      ],
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.title,
    required this.code,
    required this.balance,
  });

  final String title;
  final String code;
  final Money? balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.secondary),
          const SizedBox(height: 8),
          Text(code, style: AppTextStyles.headline),
          if (balance != null)
            Text(
              'Balance ${formatMoney(balance!, withCode: true)}',
              style: AppTextStyles.secondary,
            ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final SwapReady state;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('From ${formatMoney(quote.from, withCode: true)}'),
        Text('To ${formatMoney(quote.to, withCode: true)}'),
        Text('Freshness ${quote.freshness.name}'),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('swap_confirm'),
          onPressed: () async {
            final stepped = await confirmStepUpPin(context);
            if (!context.mounted) {
              return;
            }
            await context.read<SwapCubit>().confirm(
                  requestId: 'swap-1',
                  stepUp: stepped,
                );
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.state});

  final SwapReady state;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    final label = switch (result) {
      StaleQuoteFailure() => 'Quote is stale — swap rejected',
      StepUpFailure() => 'Step-up required',
      SwapSubmit(:final settlement) => 'Settlement ${settlement.name}',
      Failure() => '$result',
      _ => 'Unknown result',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, key: const Key('swap_result')),
          if (result is SwapSubmit &&
              (result.settlement == SettlementStatus.confirmed ||
                  result.settlement == SettlementStatus.inFlight))
            TextButton(
              key: const Key('view_orders'),
              onPressed: () => context.push(AppRoute.orders.path),
              child: const Text('View orders'),
            ),
        ],
      ),
    );
  }
}
