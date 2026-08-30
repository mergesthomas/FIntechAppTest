import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_local_datasource.dart';

final class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._local);

  final OrdersLocalDataSource _local;

  @override
  Future<Either<Failure, List<TradeOrder>>> getHistory(OrderTab tab) async {
    return Either.right(_local.history(tab));
  }

  @override
  Future<Either<Failure, TradeOrder>> getDetail(String id) async {
    final order = _local.detail(id);
    if (order == null) {
      return Either.left(const ValidationFailure('order_not_found'));
    }
    return Either.right(order);
  }

  @override
  Future<Either<Failure, SettlementStatus>> cancel({
    required String requestId,
    required String orderId,
  }) async {
    return Either.right(
      _local.cancel(requestId: requestId, orderId: orderId),
    );
  }
}
