import 'package:fpdart/fpdart.dart';

import '../../../../core/auth/eligibility_status.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../../auth/domain/usecases/session_usecases.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

final class GetOrderHistory implements UseCase<List<TradeOrder>, OrderTab> {
  GetOrderHistory(this._session, this._repo);

  final RequireSession _session;
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, List<TradeOrder>>> call(OrderTab tab) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getHistory(tab));
  }
}

final class GetOpenOrdersForAsset
    implements UseCase<List<TradeOrder>, Currency> {
  GetOpenOrdersForAsset(this._session, this._repo);

  final RequireSession _session;
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, List<TradeOrder>>> call(Currency asset) async {
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getOpenForAsset(asset));
  }
}

final class GetOrderDetail implements UseCase<TradeOrder, String> {
  GetOrderDetail(this._session, this._repo);

  final RequireSession _session;
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, TradeOrder>> call(String id) async {
    if (id.isEmpty) {
      return Either.left(const ValidationFailure('order_id_required'));
    }
    final session = await _session(const NoParams());
    return session.fold(Either.left, (_) => _repo.getDetail(id));
  }
}

final class CancelOrder
    implements
        UseCase<
          SettlementStatus,
          ({String requestId, String orderId, bool stepUp})
        > {
  CancelOrder(this._session, this._eligibility, this._repo);

  final RequireSession _session;
  final GetEligibility _eligibility;
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, SettlementStatus>> call(
    ({String requestId, String orderId, bool stepUp}) params,
  ) async {
    if (params.requestId.isEmpty) {
      return Either.left(const ValidationFailure('request_id_required'));
    }
    if (!params.stepUp) {
      return Either.left(const StepUpFailure());
    }
    final session = await _session(const NoParams());
    return session.fold((failure) async => Either.left(failure), (_) async {
      final status = await _eligibility(const NoParams());
      return status.fold((failure) async => Either.left(failure), (
        value,
      ) async {
        if (value != EligibilityStatus.approved) {
          return Either.left(const EligibilityFailure());
        }
        return _repo.cancel(
          requestId: params.requestId,
          orderId: params.orderId,
        );
      });
    });
  }
}
