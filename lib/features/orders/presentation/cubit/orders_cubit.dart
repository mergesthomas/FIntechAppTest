import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/orders_usecases.dart';

sealed class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersEmpty extends OrdersState {
  const OrdersEmpty();
}

final class OrdersFailure extends OrdersState {
  const OrdersFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class OrdersSuccess extends OrdersState {
  const OrdersSuccess({required this.tab, required this.orders});

  final OrderTab tab;
  final List<TradeOrder> orders;

  @override
  List<Object?> get props => [tab, orders];
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._getHistory) : super(const OrdersLoading());

  final GetOrderHistory _getHistory;

  Future<void> load([OrderTab tab = OrderTab.trigger]) async {
    emit(const OrdersLoading());
    final result = await _getHistory(tab);
    result.fold(
      (failure) => emit(OrdersFailure(failure)),
      (orders) => emit(
        orders.isEmpty
            ? const OrdersEmpty()
            : OrdersSuccess(tab: tab, orders: orders),
      ),
    );
  }
}
