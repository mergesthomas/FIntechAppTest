import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/clock/chart_time_label.dart';
import '../../../../core/money/money_format.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_failure_view.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/entities/order.dart';
import '../cubit/orders_cubit.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrdersCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          bottom: TabBar(
            onTap: (index) => context.read<OrdersCubit>().load(
                  switch (index) {
                    0 => OrderTab.trigger,
                    1 => OrderTab.limit,
                    _ => OrderTab.market,
                  },
                ),
            tabs: const [
              Tab(text: 'Trigger'),
              Tab(text: 'Limit'),
              Tab(text: 'Market'),
            ],
          ),
        ),
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            return switch (state) {
              OrdersLoading() =>
                const Center(child: CircularProgressIndicator()),
              OrdersEmpty() => const AppEmptyState(message: 'No orders'),
              OrdersFailure(:final failure) => AppFailureView(
                failure: failure,
                onRetry: () => context.read<OrdersCubit>().load(),
              ),
              OrdersSuccess(:final orders) => _OrderList(orders: orders),
            };
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<TradeOrder> orders;

  @override
  Widget build(BuildContext context) {
    final grouped = <OrderStatus, List<TradeOrder>>{};
    for (final order in orders) {
      grouped.putIfAbsent(order.status, () => []).add(order);
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xs,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      children: [
        for (final status in OrderStatus.values)
          if (grouped[status] case final rows?) ...[
            AppSectionHeader(_statusLabel(status)),
            for (final order in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.pair} ${order.side.name.toUpperCase()}',
                            style: AppTextStyles.body,
                          ),
                          if (order.occurredAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              chartTimeLabel(
                                order.occurredAt!,
                                includeTime: true,
                              ),
                              style: AppTextStyles.meta.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      formatQuantity(order.amount),
                      style: AppTextStyles.numeric,
                    ),
                  ],
                ),
              ),
          ],
      ],
    );
  }

  String _statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.open => 'Open',
      OrderStatus.filled => 'Filled',
      OrderStatus.canceled => 'Canceled',
    };
  }
}
