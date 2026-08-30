import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/freshness_chip.dart';
import '../../../../core/widgets/price_chart.dart';
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
      appBar: AppBar(
        title: const Text('Futures'),
        actions: [
          IconButton(
            tooltip: 'Orders',
            onPressed: () => context.push(AppRoute.orders.path),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
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
        Row(
          children: [
            Expanded(
              child: Text(instrument.pair, style: AppTextStyles.headline),
            ),
            FreshnessChip(freshness: instrument.freshness),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Bid ${formatMoney(instrument.bid, withCode: true)} · Ask ${formatMoney(instrument.ask, withCode: true)}',
          style: AppTextStyles.secondary,
        ),
        const SizedBox(height: 12),
        PriceChart(points: instrument.chart, height: 160),
        const SizedBox(height: 8),
        Text(instrument.leverageTeasers.join(' · '), style: AppTextStyles.secondary),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                key: const Key('futures_preview'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                ),
                onPressed: () => context.read<FuturesCubit>().preview(
                      side: FuturesSide.long,
                    ),
                child: const Text('Long'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('futures_short'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.textPrimary,
                ),
                onPressed: () => context.read<FuturesCubit>().preview(
                      side: FuturesSide.short,
                    ),
                child: const Text('Short'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Available ${formatMoney(state.account.availableMargin, withCode: true)}',
          style: AppTextStyles.body,
        ),
        Text(state.account.riskTeaser, style: AppTextStyles.secondary),
        Text(state.account.bonusTeaser, style: AppTextStyles.secondary),
        const SizedBox(height: 16),
        Text('Open positions', style: AppTextStyles.headline),
        for (final position in state.positions)
          ListTile(
            key: Key('position_${position.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text('${position.pair} ${position.side.name.toUpperCase()}'),
            subtitle: Text(
              '${position.leverageTeaser} · ${formatMoney(position.size, withCode: true)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.read<FuturesCubit>().openPosition(position.id),
          ),
        Text('Last trades', style: AppTextStyles.headline),
        for (final trade in state.trades)
          ListTile(
            contentPadding: EdgeInsets.zero,
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
        Text(
          '${quote.side.name.toUpperCase()} ${formatMoney(quote.size, withCode: true)}',
          style: AppTextStyles.headline,
        ),
        Text(quote.leverageTeaser),
        Text('Freshness ${quote.freshness.name}'),
        const SizedBox(height: 16),
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
