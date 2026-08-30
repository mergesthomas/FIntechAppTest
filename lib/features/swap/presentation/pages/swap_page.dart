import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money_format.dart';
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
      appBar: AppBar(title: const Text('Exchange')),
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
        const ListTile(title: Text('Instant order · From NEXO → To EURx')),
        TextField(
          key: const Key('swap_amount'),
          decoration: const InputDecoration(labelText: 'From amount'),
          onChanged: context.read<SwapCubit>().typeAmount,
        ),
        ElevatedButton(
          key: const Key('swap_preview'),
          onPressed: () => context.read<SwapCubit>().preview(),
          child: const Text('Preview order'),
        ),
      ],
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
    return Center(child: Text(label, key: const Key('swap_result')));
  }
}
