import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money_format.dart';
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order History'),
          bottom: TabBar(
            onTap: (index) => context.read<OrdersCubit>().load(
                  index == 0 ? OrderTab.trigger : OrderTab.limit,
                ),
            tabs: const [
              Tab(text: 'Trigger Orders'),
              Tab(text: 'Limit Orders'),
            ],
          ),
        ),
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            return switch (state) {
              OrdersLoading() =>
                const Center(child: CircularProgressIndicator()),
              OrdersEmpty() => const Center(child: Text('No orders')),
              OrdersFailure(:final failure) => Center(child: Text('$failure')),
              OrdersSuccess(:final orders) => ListView(
                  children: [
                    for (final order in orders)
                      ListTile(
                        title: Text('${order.pair} ${order.side.name.toUpperCase()}'),
                        subtitle: Text(
                          '${order.status.name.toUpperCase()} · ${order.wallet}',
                        ),
                        trailing: Text(formatMoney(order.amount, withCode: true)),
                      ),
                  ],
                ),
            };
          },
        ),
      ),
    );
  }
}
