import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/futures.dart';
import '../../domain/repositories/futures_repository.dart';
import '../datasources/futures_local_datasource.dart';

final class FuturesRepositoryImpl implements FuturesRepository {
  FuturesRepositoryImpl(this._local);

  final FuturesLocalDataSource _local;

  @override
  Future<Either<Failure, FuturesInstrument>> getInstrument() async {
    return Either.right(_local.instrument());
  }

  @override
  Future<Either<Failure, FuturesAccount>> getAccount() async {
    return Either.right(_local.account());
  }

  @override
  Future<Either<Failure, List<FuturesPosition>>> getOpenPositions() async {
    return Either.right(_local.positions());
  }

  @override
  Future<Either<Failure, FuturesPositionDetails>> getPositionDetails(
    String id,
  ) async {
    final details = _local.details(id);
    if (details == null) {
      return Either.left(const ValidationFailure('position_not_found'));
    }
    return Either.right(details);
  }

  @override
  Future<Either<Failure, List<FuturesTrade>>> getLastTrades() async {
    return Either.right(_local.lastTrades());
  }

  @override
  Future<Either<Failure, FuturesQuote>> getQuote({
    required FuturesSide side,
    required Money size,
  }) async {
    return Either.right(_local.quote(side: side, size: size));
  }

  @override
  Future<Either<Failure, FuturesQuote>> getQuoteById(String quoteId) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    return Either.right(quote);
  }

  @override
  Future<Either<Failure, FuturesSubmit>> submit({
    required String requestId,
    required String quoteId,
  }) async {
    return Either.right(_local.submit(requestId: requestId, quoteId: quoteId));
  }

  @override
  Future<Either<Failure, SettlementStatus>> setTakeProfitStopLoss({
    required String requestId,
    required String positionId,
  }) async {
    return Either.right(_local.settleOnce(requestId));
  }

  @override
  Future<Either<Failure, SettlementStatus>> closePosition({
    required String requestId,
    required String positionId,
  }) async {
    return Either.right(_local.settleOnce(requestId));
  }
}
