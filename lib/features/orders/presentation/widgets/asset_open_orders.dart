import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/clock/chart_time_label.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/notice/failure_message.dart';
import '../../../../core/notice/user_notice.dart';
import '../../../../core/notice/user_notice_cubit.dart';
import '../../../../core/router/app_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../auth/presentation/widgets/step_up_pin_dialog.dart';
import '../../domain/entities/order.dart';
import '../cubit/open_orders_cubit.dart';

class AssetOpenOrders extends StatelessWidget {
  const AssetOpenOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OpenOrdersCubit, OpenOrdersState>(
      listenWhen: (previous, current) {
        final prev = previous is OpenOrdersReady ? previous.failure : null;
        final next = current is OpenOrdersReady ? current.failure : null;
        return next != null && next != prev;
      },
      listener: (context, state) {
        if (state is! OpenOrdersReady || state.failure == null) {
          return;
        }
        context.showUserNotice(
          UserNotice.error(FailureMessage.map(state.failure!)),
        );
        context.read<OpenOrdersCubit>().clearFailure();
      },
      child: BlocBuilder<OpenOrdersCubit, OpenOrdersState>(
        builder: (context, state) {
          return switch (state) {
            OpenOrdersReady(:final orders) => _List(orders: orders),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.orders});

  final List<TradeOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Open orders', style: AppTextStyles.secondary),
        const SizedBox(height: AppSpacing.xs),
        for (final order in orders)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OrderCard(order: order),
          ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final TradeOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<OpenOrdersCubit>();
    final submitting = cubit.state is OpenOrdersReady &&
        (cubit.state as OpenOrdersReady).submittingId == order.id;
    final type = order.tab == OrderTab.trigger ? 'Trigger' : 'Limit';
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$type · ${order.pair}', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            formatQuantity(order.amount),
            style: AppTextStyles.numeric,
          ),
          if (order.limitPrice != null)
            Text(
              'Limit ${formatQuantity(order.limitPrice!)}',
              style: AppTextStyles.meta.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (order.occurredAt != null)
            Text(
              chartTimeLabel(order.occurredAt!, includeTime: true),
              style: AppTextStyles.meta.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: Key('open_order_edit_${order.id}'),
                  onPressed: submitting
                      ? null
                      : () => context.push(_editLink(order)),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlinedButton(
                  key: Key('open_order_cancel_${order.id}'),
                  onPressed: submitting
                      ? null
                      : () async {
                          final stepped = await confirmStepUpPin(context);
                          if (!context.mounted) {
                            return;
                          }
                          await cubit.cancel(
                            orderId: order.id,
                            stepUp: stepped,
                          );
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _editLink(TradeOrder order) {
    final to = order.receive?.code ?? _quote(order.pair);
    final quote = order.pay?.code ?? _base(order.pair);
    final type = order.tab == OrderTab.trigger ? 'trigger' : 'limit';
    return Uri(
      path: AppRoute.swap.path,
      queryParameters: {
        'to': to,
        'quote': quote,
        'type': type,
        if (order.limitPrice != null)
          'limitPrice': order.limitPrice!.amount.toString(),
        if (order.takeProfit != null)
          'takeProfit': order.takeProfit!.amount.toString(),
        if (order.stopLoss != null)
          'stopLoss': order.stopLoss!.amount.toString(),
      },
    ).toString();
  }

  String _base(String pair) {
    final split = pair.indexOf('/');
    return split < 0 ? pair : pair.substring(0, split);
  }

  String _quote(String pair) {
    final split = pair.indexOf('/');
    return split < 0 ? pair : pair.substring(split + 1);
  }
}
