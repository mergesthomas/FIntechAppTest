import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/step_up_pin_dialog.dart';
import '../../domain/entities/futures.dart';
import '../cubit/futures_cubit.dart';

class FuturesPage extends StatefulWidget {
  const FuturesPage({super.key});

  @override
  State<FuturesPage> createState() => _FuturesPageState();
}

class _FuturesPageState extends State<FuturesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FuturesCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Futures')),
      body: BlocBuilder<FuturesCubit, FuturesState>(
        builder: (context, state) {
          return switch (state) {
            FuturesLoading() => const Center(child: CircularProgressIndicator()),
            FuturesEmpty() => const Center(child: Text('No futures data')),
            FuturesFailure(:final failure) => Center(child: Text('$failure')),
            FuturesReady() => switch (state.surface) {
                FuturesSurface.ticket => _Ticket(state: state),
                FuturesSurface.preview => _Preview(state: state),
                FuturesSurface.position => _Position(state: state),
                FuturesSurface.result => _Result(state: state),
              },
          };
        },
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.state});

  final FuturesReady state;

  @override
  Widget build(BuildContext context) {
    final instrument = state.instrument;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(instrument.pair, style: AppTextStyles.headline),
        Text(
          'Bid ${formatMoney(instrument.bid, withCode: true)} · Ask ${formatMoney(instrument.ask, withCode: true)} · ${instrument.freshness.name}',
        ),
        Text(instrument.leverageTeasers.join(' · ')),
        Text(
          'Available ${formatMoney(state.account.availableMargin, withCode: true)}',
        ),
        Text(state.account.riskTeaser, style: AppTextStyles.secondary),
        Text(state.account.bonusTeaser, style: AppTextStyles.secondary),
        ElevatedButton(
          key: const Key('futures_preview'),
          onPressed: () => context.read<FuturesCubit>().preview(),
          child: const Text('Preview position'),
        ),
        const SizedBox(height: 12),
        Text('Open positions', style: AppTextStyles.headline),
        for (final position in state.positions)
          ListTile(
            key: Key('position_${position.id}'),
            title: Text('${position.pair} ${position.side.name.toUpperCase()}'),
            subtitle: Text(
              '${position.leverageTeaser} · ${formatMoney(position.size, withCode: true)}',
            ),
            onTap: () => context.read<FuturesCubit>().openPosition(position.id),
          ),
        Text('Last trades', style: AppTextStyles.headline),
        for (final trade in state.trades)
          ListTile(
            title: Text(trade.side.name.toUpperCase()),
            subtitle: Text(
              '${formatMoney(trade.price, withCode: true)} · ${formatMoney(trade.size, withCode: true)}',
            ),
          ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final FuturesReady state;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('${quote.side.name} ${formatMoney(quote.size, withCode: true)}'),
        Text(quote.leverageTeaser),
        Text('Freshness ${quote.freshness.name}'),
        ElevatedButton(
          key: const Key('futures_confirm'),
          onPressed: () async {
            final stepped = await confirmStepUpPin(context);
            if (!context.mounted) {
              return;
            }
            await context.read<FuturesCubit>().confirm(
                  requestId: 'fut-1',
                  stepUp: stepped,
                );
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _Position extends StatelessWidget {
  const _Position({required this.state});

  final FuturesReady state;

  @override
  Widget build(BuildContext context) {
    final details = state.details!;
    final position = details.position;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${position.pair} ${position.side.name.toUpperCase()}',
          style: AppTextStyles.headline,
        ),
        Text('P/L ${formatMoney(details.pnl, withCode: true)}'),
        Text('Entry ${formatMoney(details.entry, withCode: true)}'),
        Text(
          'Mark ${formatMoney(details.mark, withCode: true)} · ${details.markFreshness.name}',
        ),
        Text('Liq ${formatMoney(details.liquidation, withCode: true)}'),
        Text(
          'Locked ${formatMoney(details.lockedCollateral, withCode: true)}',
        ),
        Text(
          'Maintenance ${formatMoney(details.maintenanceMargin, withCode: true)}',
        ),
        Text(details.fundingTeaser),
        Text('Order ${details.orderId}'),
        ElevatedButton(
          key: const Key('futures_tpsl'),
          onPressed: () async {
            final stepped = await confirmStepUpPin(context);
            if (!context.mounted) {
              return;
            }
            await context.read<FuturesCubit>().setTpsl(
                  positionId: position.id,
                  requestId: 'tpsl-${position.id}',
                  stepUp: stepped,
                );
          },
          child: const Text('Set TP/SL'),
        ),
        TextButton(
          key: Key('close_${position.id}'),
          onPressed: () async {
            final stepped = await confirmStepUpPin(context);
            if (!context.mounted) {
              return;
            }
            await context.read<FuturesCubit>().closePosition(
                  positionId: position.id,
                  requestId: 'close-${position.id}',
                  stepUp: stepped,
                );
          },
          child: const Text('Close position'),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.state});

  final FuturesReady state;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    final label = switch (result) {
      StaleQuoteFailure() => 'Quote is stale — futures order rejected',
      StepUpFailure() => 'Step-up required',
      FuturesSubmit(:final settlement) => 'Settlement ${settlement.name}',
      SettlementStatus() => 'Settlement ${result.name}',
      Failure() => '$result',
      _ => 'Unknown result',
    };
    return Center(child: Text(label, key: const Key('futures_result')));
  }
}
