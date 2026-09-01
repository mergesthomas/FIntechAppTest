import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/ledger/paper_ledger.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_local_datasource.dart';

final class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._local, {PaperLedger? ledger}) : _ledger = ledger;

  final OrdersLocalDataSource _local;
  final PaperLedger? _ledger;

  @override
  Future<Either<Failure, List<TradeOrder>>> getHistory(OrderTab tab) async {
    return Either.right(_local.history(tab));
  }

  @override
  Future<Either<Failure, List<TradeOrder>>> getOpenForAsset(
    Currency asset,
  ) async {
    return Either.right(_local.openForAsset(asset));
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
    final ledger = _ledger;
    if (ledger != null && ledger.orders.byId(orderId) != null) {
      return ledger.cancelHold(requestId: requestId, orderId: orderId);
    }
    return Either.right(
      _local.cancel(requestId: requestId, orderId: orderId),
    );
  }
}
