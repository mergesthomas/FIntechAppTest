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
import '../../../../core/notice/failure_message.dart';
import '../../../../core/notice/user_notice.dart';
import '../../../../core/notice/user_notice_cubit.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/app_picker_sheet.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await context.read<SwapCubit>().load();
      if (!mounted) {
        return;
      }
      final params = GoRouterState.of(context).uri.queryParameters;
      context.read<SwapCubit>().applyRouteSeed(
        toCode: params['to'],
        quoteCode: params['quote'],
        type: params['type'],
        limitPrice: params['limitPrice'],
        takeProfit: params['takeProfit'],
        stopLoss: params['stopLoss'],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SwapCubit, SwapState>(
      listenWhen: (previous, current) {
        final prev = previous is SwapReady ? previous.ticketFailure : null;
        final next = current is SwapReady ? current.ticketFailure : null;
        return next != null && next != prev;
      },
      listener: (context, state) {
        if (state is! SwapReady || state.ticketFailure == null) {
          return;
        }
        context.showUserNotice(
          UserNotice.error(SwapCopy.ticketFailure(state.ticketFailure!)),
        );
        context.read<SwapCubit>().clearTicketFailure();
      },
      child: BlocBuilder<SwapCubit, SwapState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state is SwapReady && state.surface == SwapSurface.preview
                  ? SwapCopy.previewTitle
                  : SwapCopy.title,
            ),
            leading:
                state is SwapReady && state.surface != SwapSurface.ticket
                    ? IconButton(
                      key: const Key('swap_close'),
                      onPressed: context.read<SwapCubit>().backToTicket,
                      icon: const Icon(Icons.close),
                    )
                    : (ModalRoute.of(context)?.canPop ?? false)
                    ? null
                    : IconButton(
                      tooltip: SwapCopy.info,
                      onPressed:
                          () => context.showUserNotice(
                            UserNotice.info(SwapCopy.info),
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
            SwapFailure(:final failure) => AppFailureView(
              failure: failure,
              onRetry: context.read<SwapCubit>().load,
            ),
            SwapReady() => switch (state.surface) {
              SwapSurface.ticket => _Ticket(state: state),
              SwapSurface.preview => _Preview(state: state),
              SwapSurface.result => _Result(state: state),
            },
          },
        );
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
            onPressed: state.canPreview ? cubit.preview : null,
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
    return '+ ${formatQuantity(receive, withCode: false)}';
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
        key:
            key == const Key('swap_from_asset')
                ? const Key('swap_amount')
                : null,
        onTap: onFocus,
        borderRadius: AppRadii.card,
        child: AppSurface(
          selected: selected,
          child: Row(
            children: [
              Flexible(
                child: GestureDetector(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    code,
                                    style: AppTextStyles.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.expand_more,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            if (balance != null)
                              Text(
                                formatQuantity(balance!, withCode: false),
                                style: AppTextStyles.secondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountLabel,
                      style: AppTextStyles.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                    if (cashback)
                      Text(
                        SwapCopy.cashbackLabel.split(' (').first,
                        style: AppTextStyles.meta.copyWith(
                          color: scheme.tertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
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
  const _RateLine({required this.rate, required this.from, required this.to});

  final SwapRate rate;
  final Currency from;
  final Currency to;

  @override
  Widget build(BuildContext context) {
    final text =
        '1 ${from.code} = ${formatRate(rate.toPerFrom)}';
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
          '+ ${formatQuantity(quote.to)}',
          style: AppTextStyles.balance,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.lg),
        DetailRow(
          label: SwapCopy.payWith,
          value: '- ${formatQuantity(quote.from)}',
        ),
        const SizedBox(height: AppSpacing.md),
        DetailRow(
          label: SwapCopy.orderType,
          value: SwapCopy.orderTypeLabel(quote.type.name),
        ),
        DetailRow(
          label: SwapCopy.exchangeRate,
          value:
              '1 ${quote.from.currency.code} = ${formatRate(Money.fromDecimal((quote.to.amount / quote.from.amount).toDecimal(scaleOnInfinitePrecision: 18), quote.to.currency))}',
        ),
        DetailRow(label: SwapCopy.feeApplied, value: SwapCopy.feeValue),
        DetailRow(
          label: SwapCopy.cashbackLabel,
          value: formatQuantity(cashback),
          emphasize: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          key: const Key('swap_confirm'),
          onPressed: state.submitting
              ? null
              : () async {
                  final stepped = await confirmStepUpPin(context);
                  if (!context.mounted) {
                    return;
                  }
                  await context.read<SwapCubit>().confirm(stepUp: stepped);
                },
          child: state.submitting
              ? const SizedBox(
                  key: Key('swap_confirm_spinner'),
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(SwapCopy.confirmCta),
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
    final quote = state.quote;
    final scheme = Theme.of(context).colorScheme;
    final submit = result is SwapSubmit ? result : null;
    final headline = switch (result) {
      StaleQuoteFailure() => SwapCopy.staleQuote,
      StepUpFailure() => SwapCopy.stepUpRequired,
      SwapSubmit(:final settlement, :final venue) =>
        SwapCopy.settlementHeadline(
          settlement: settlement,
          resting: venue != PaperVenue.market,
        ),
      Failure() => FailureMessage.map(result),
      _ => SwapCopy.unknownStatus,
    };
    final icon = switch (submit?.settlement) {
      SettlementStatus.confirmed => Icons.check_circle_outline,
      SettlementStatus.inFlight => Icons.hourglass_empty,
      SettlementStatus.failed => Icons.error_outline,
      SettlementStatus.unknown => Icons.help_outline,
      null => Icons.error_outline,
    };
    final iconColor = switch (submit?.settlement) {
      SettlementStatus.confirmed => scheme.tertiary,
      SettlementStatus.inFlight => scheme.onSurfaceVariant,
      SettlementStatus.failed => scheme.error,
      SettlementStatus.unknown => scheme.error,
      null => scheme.error,
    };
    final showOrders =
        submit != null &&
        (submit.settlement == SettlementStatus.confirmed ||
            submit.settlement == SettlementStatus.inFlight ||
            submit.settlement == SettlementStatus.unknown);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        Icon(icon, size: 48, color: iconColor),
        const SizedBox(height: AppSpacing.md),
        Text(
          headline,
          key: const Key('swap_result'),
          style: AppTextStyles.headline,
          textAlign: TextAlign.center,
        ),
        if (quote != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            SwapCopy.orderTypeLabel(quote.type.name),
            style: AppTextStyles.secondary.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSurface(
            child: Column(
              children: [
                DetailRow(
                  label: SwapCopy.payWith,
                  value: '- ${formatQuantity(quote.from)}',
                ),
                DetailRow(
                  label: SwapCopy.receive,
                  value: '+ ${formatQuantity(quote.to)}',
                ),
                if (submit != null)
                  DetailRow(
                    label: SwapCopy.status,
                    value: SwapCopy.settlementStatus(submit.settlement),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (showOrders)
          ElevatedButton(
            key: const Key('view_orders'),
            onPressed: () => context.push(AppRoute.orders.path),
            child: const Text(SwapCopy.viewOrders),
          ),
        if (showOrders) const SizedBox(height: AppSpacing.sm),
        TextButton(
          key: const Key('swap_done'),
          onPressed: context.read<SwapCubit>().backToTicket,
          child: const Text(SwapCopy.done),
        ),
      ],
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
  final current = cubit.state;
  final selectedType =
      current is SwapReady ? current.orderType : SwapOrderType.instant;
  final selected = await showModalBottomSheet<SwapOrderType>(
    context: context,
    showDragHandle: false,
    builder: (sheet) {
      return AppPickerSheet(
        title: SwapCopy.orderType,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in SwapOrderType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('swap_type_${type.name}'),
                    onTap: () => Navigator.pop(sheet, type),
                    borderRadius: AppRadii.card,
                    child: AppSurface(
                      selected: type == selectedType,
                      child: Row(
                        children: [
                          Icon(_orderTypeIcon(type)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              SwapCopy.orderTypeLabel(type.name),
                              style: AppTextStyles.body,
                            ),
                          ),
                          if (type == selectedType)
                            Icon(
                              Icons.check,
                              color: Theme.of(sheet).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
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

IconData _orderTypeIcon(SwapOrderType type) {
  return switch (type) {
    SwapOrderType.instant => Icons.bolt_outlined,
    SwapOrderType.limit => Icons.tune,
    SwapOrderType.trigger => Icons.notifications_outlined,
  };
}

Future<void> _pickAsset(BuildContext context, {required bool pay}) async {
  final cubit = context.read<SwapCubit>();
  final state = cubit.state;
  if (state is! SwapReady) {
    return;
  }
  final selected = await showModalBottomSheet<Currency>(
    context: context,
    showDragHandle: false,
    builder: (sheet) {
      final exclude = pay ? state.to : state.from;
      return AppPickerSheet(
        title: pay ? SwapCopy.payWith : SwapCopy.receive,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final asset in state.assets)
              if (asset.currency != exclude)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('swap_pick_${asset.currency.code}'),
                      onTap: () => Navigator.pop(sheet, asset.currency),
                      borderRadius: AppRadii.card,
                      child: AppSurface(
                        selected: asset.currency == (pay ? state.from : state.to),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                asset.currency.code,
                                style: AppTextStyles.body,
                              ),
                            ),
                            Text(
                              formatQuantity(asset.balance),
                              style: AppTextStyles.numeric,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
