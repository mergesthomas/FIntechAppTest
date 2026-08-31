import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/ledger/paper_order.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/detail_row.dart';
import '../../../auth/presentation/widgets/step_up_pin_dialog.dart';
import '../../domain/entities/swap.dart';
import '../copy/swap_copy.dart';
import '../cubit/swap_cubit.dart';
import '../widgets/swap_keypad.dart';

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
    return BlocBuilder<SwapCubit, SwapState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state is SwapReady && state.surface == SwapSurface.preview
                  ? SwapCopy.previewTitle
                  : SwapCopy.title,
            ),
            leading: state is SwapReady &&
                    state.surface != SwapSurface.ticket
                ? IconButton(
                    key: const Key('swap_close'),
                    onPressed: context.read<SwapCubit>().backToTicket,
                    icon: const Icon(Icons.close),
                  )
                : (ModalRoute.of(context)?.canPop ?? false)
                    ? null
                    : IconButton(
                        tooltip: SwapCopy.info,
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(SwapCopy.info)),
                        ),
                        icon: const Icon(Icons.info_outline),
                      ),
            actions: [
              IconButton(
                tooltip: SwapCopy.orders,
                onPressed: () => context.push(AppRoute.orders.path),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
            ],
          ),
          body: switch (state) {
            SwapLoading() => const Center(child: CircularProgressIndicator()),
            SwapEmpty() => const AppEmptyState(message: SwapCopy.noAssets),
            SwapFailure(:final failure) => AppEmptyState(
                message: '$failure',
                actionLabel: 'Retry',
                onAction: context.read<SwapCubit>().load,
              ),
            SwapReady() => switch (state.surface) {
                SwapSurface.ticket => _Ticket(state: state),
                SwapSurface.preview => _Preview(state: state),
                SwapSurface.result => _Result(state: state),
              },
          },
        );
      },
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.state});

  final SwapReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SwapCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('swap_order_type'),
            onPressed: () => _pickOrderType(context),
            child: Text(SwapCopy.orderTypeLabel(state.orderType.name)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AssetCard(
          key: const Key('swap_from_asset'),
          code: state.from.code,
          balance: state.fromBalance,
          amountLabel: _signedAmount(state.amountInput, negative: true),
          selected: state.inputField == SwapInputField.payAmount,
          onSelectAsset: () => _pickAsset(context, pay: true),
          onFocus: () => cubit.focusField(SwapInputField.payAmount),
        ),
        Align(
          child: IconButton(
            key: const Key('swap_flip'),
            onPressed: cubit.flip,
            icon: const Icon(Icons.arrow_downward),
          ),
        ),
        _AssetCard(
          key: const Key('swap_to_asset'),
          code: state.to.code,
          balance: state.toBalance,
          amountLabel: _receiveLabel(state),
          selected: false,
          cashback: state.amountInput.isNotEmpty,
          onSelectAsset: () => _pickAsset(context, pay: false),
          onFocus: () {},
        ),
        if (state.orderType == SwapOrderType.limit) ...[
          const SizedBox(height: AppSpacing.sm),
          _PriceRow(
            key: const Key('swap_limit_price'),
            label: SwapCopy.limitPrice,
            value: state.limitInput,
            unit: state.from.code,
            selected: state.inputField == SwapInputField.limitPrice,
            onTap: () => cubit.focusField(SwapInputField.limitPrice),
          ),
        ],
        if (state.orderType == SwapOrderType.trigger) ...[
          const SizedBox(height: AppSpacing.sm),
          _PriceRow(
            key: const Key('swap_take_profit'),
            label: SwapCopy.takeProfit,
            value: state.tpInput,
            unit: state.from.code,
            selected: state.inputField == SwapInputField.takeProfit,
            onTap: () => cubit.focusField(SwapInputField.takeProfit),
          ),
          _PriceRow(
            key: const Key('swap_stop_loss'),
            label: SwapCopy.stopLoss,
            value: state.slInput,
            unit: state.from.code,
            selected: state.inputField == SwapInputField.stopLoss,
            onTap: () => cubit.focusField(SwapInputField.stopLoss),
          ),
        ],
        if (state.rate != null) ...[
          const SizedBox(height: AppSpacing.md),
          _RateLine(rate: state.rate!, from: state.from, to: state.to),
        ],
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          key: const Key('swap_preview'),
          onPressed: cubit.preview,
          child: const Text(SwapCopy.previewCta),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final pct in [10, 20, 30, 50])
              Expanded(
                child: TextButton(
                  key: Key('swap_pct_$pct'),
                  onPressed: () => cubit.setPercent(pct),
                  child: Text('$pct%'),
                ),
              ),
            Expanded(
              child: TextButton(
                key: const Key('swap_pct_max'),
                onPressed: () => cubit.setPercent(100),
                child: const Text(SwapCopy.pctMax),
              ),
            ),
          ],
        ),
        SwapKeypad(
          onDigit: cubit.appendKey,
          onDot: () => cubit.appendKey('.'),
          onBackspace: cubit.backspace,
        ),
        ],
      ),
    );
  }

  String _receiveLabel(SwapReady state) {
    final amount = _tryParse(state.amountInput, state.from);
    final rate = state.rate;
    if (amount == null || rate == null) {
      return '+ 0';
    }
    final receive = amount.convert(rate.toPerFrom.amount, state.to);
    return '+ ${formatMoney(receive, withCode: false)}';
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    super.key,
    required this.code,
    required this.balance,
    required this.amountLabel,
    required this.selected,
    required this.onSelectAsset,
    required this.onFocus,
    this.cashback = false,
  });

  final String code;
  final Money? balance;
  final String amountLabel;
  final bool selected;
  final VoidCallback onSelectAsset;
  final VoidCallback onFocus;
  final bool cashback;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key == const Key('swap_from_asset')
            ? const Key('swap_amount')
            : null,
        onTap: onFocus,
        borderRadius: AppRadii.card,
        child: AppSurface(
          selected: selected,
          child: Row(
            children: [
              GestureDetector(
                onTap: onSelectAsset,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.surfaceContainerHighest,
                      foregroundColor: scheme.onSurface,
                      child: Text(
                        code.substring(0, 1),
                        style: AppTextStyles.meta.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(code, style: AppTextStyles.body),
                            Icon(
                              Icons.expand_more,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        if (balance != null)
                          Text(
                            formatMoney(balance!, withCode: false),
                            style: AppTextStyles.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amountLabel, style: AppTextStyles.headline),
                  if (cashback)
                    Text(
                      SwapCopy.cashbackLabel.split(' (').first,
                      style: AppTextStyles.meta.copyWith(
                        color: scheme.tertiary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: AppSurface(
          selected: selected,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.secondary)),
              Text(
                value.isEmpty ? SwapCopy.setPrice : '$value $unit',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateLine extends StatelessWidget {
  const _RateLine({
    required this.rate,
    required this.from,
    required this.to,
  });

  final SwapRate rate;
  final Currency from;
  final Currency to;

  @override
  Widget build(BuildContext context) {
    final text =
        '1 ${from.code} = ${formatMoney(rate.toPerFrom, withCode: true)}';
    final status = rate.freshness.statusLabel;
    final freshness = status == null ? '' : ' · $status';
    return Text(
      '$text$freshness',
      key: const Key('swap_rate'),
      style: AppTextStyles.secondary,
      textAlign: TextAlign.center,
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final SwapReady state;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote!;
    final cashback = Money.fromDecimal(
      quote.to.amount * Decimal.parse(SwapCopy.cashbackRate),
      quote.to.currency,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Text(
          SwapCopy.receive,
          style: AppTextStyles.secondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '+ ${formatMoney(quote.to, withCode: true)}',
          style: AppTextStyles.balance,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        DetailRow(
          label: SwapCopy.payWith,
          value: '- ${formatMoney(quote.from, withCode: true)}',
        ),
        const SizedBox(height: AppSpacing.md),
        DetailRow(
          label: SwapCopy.orderType,
          value: SwapCopy.orderTypeLabel(quote.type.name),
        ),
        DetailRow(
          label: SwapCopy.exchangeRate,
          value:
              '1 ${quote.from.currency.code} = ${formatMoney(Money.fromDecimal((quote.to.amount / quote.from.amount).toDecimal(scaleOnInfinitePrecision: 18), quote.to.currency), withCode: true)}',
        ),
        DetailRow(label: SwapCopy.feeApplied, value: SwapCopy.feeValue),
        DetailRow(
          label: SwapCopy.cashbackLabel,
          value: formatMoney(cashback, withCode: true),
          emphasize: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          key: const Key('swap_confirm'),
          onPressed: () async {
            final stepped = await confirmStepUpPin(context);
            if (!context.mounted) {
              return;
            }
            await context.read<SwapCubit>().confirm(
                  requestId: 'swap-${DateTime.now().microsecondsSinceEpoch}',
                  stepUp: stepped,
                );
          },
          child: const Text(SwapCopy.confirmCta),
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
      SwapSubmit(:final settlement, :final venue) =>
        venue != PaperVenue.market &&
                settlement == SettlementStatus.confirmed
            ? SwapCopy.placed
            : 'Settlement ${settlement.name}',
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
              child: const Text(SwapCopy.orders),
            ),
        ],
      ),
    );
  }
}

String _signedAmount(String input, {required bool negative}) {
  if (input.isEmpty) {
    return negative ? '- 0' : '+ 0';
  }
  return '${negative ? '-' : '+'} $input';
}

Money? _tryParse(String input, Currency currency) {
  if (input.isEmpty) {
    return null;
  }
  try {
    return Money.parse(input, currency);
  } on FormatException {
    return null;
  }
}

Future<void> _pickOrderType(BuildContext context) async {
  final cubit = context.read<SwapCubit>();
  final selected = await showModalBottomSheet<SwapOrderType>(
    context: context,
    builder: (sheet) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('swap_type_instant'),
              title: const Text(SwapCopy.instant),
              onTap: () => Navigator.pop(sheet, SwapOrderType.instant),
            ),
            ListTile(
              key: const Key('swap_type_limit'),
              title: const Text(SwapCopy.limitOrder),
              onTap: () => Navigator.pop(sheet, SwapOrderType.limit),
            ),
            ListTile(
              key: const Key('swap_type_trigger'),
              title: const Text(SwapCopy.triggerOrder),
              onTap: () => Navigator.pop(sheet, SwapOrderType.trigger),
            ),
          ],
        ),
      );
    },
  );
  if (selected != null) {
    cubit.selectOrderType(selected);
  }
}

Future<void> _pickAsset(BuildContext context, {required bool pay}) async {
  final cubit = context.read<SwapCubit>();
  final state = cubit.state;
  if (state is! SwapReady) {
    return;
  }
  final selected = await showModalBottomSheet<Currency>(
    context: context,
    builder: (sheet) {
      final exclude = pay ? state.to : state.from;
      return SafeArea(
        child: ListView(
          children: [
            for (final asset in state.assets)
              if (asset.currency != exclude)
                ListTile(
                  key: Key('swap_pick_${asset.currency.code}'),
                  title: Text(asset.currency.code),
                  subtitle: Text(formatMoney(asset.balance, withCode: true)),
                  onTap: () => Navigator.pop(sheet, asset.currency),
                ),
          ],
        ),
      );
    },
  );
  if (selected == null) {
    return;
  }
  if (pay) {
    cubit.selectFrom(selected);
  } else {
    cubit.selectTo(selected);
  }
}
