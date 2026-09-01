import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../entities/order.dart';

abstract class OrdersRepository {
  Future<Either<Failure, List<TradeOrder>>> getHistory(OrderTab tab);
  Future<Either<Failure, List<TradeOrder>>> getOpenForAsset(Currency asset);
  Future<Either<Failure, TradeOrder>> getDetail(String id);
  Future<Either<Failure, SettlementStatus>> cancel({
    required String requestId,
    required String orderId,
  });
}
