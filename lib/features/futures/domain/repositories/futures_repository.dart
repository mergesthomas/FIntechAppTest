import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../entities/futures.dart';

abstract class FuturesRepository {
  Future<Either<Failure, FuturesInstrument>> getInstrument();
  Future<Either<Failure, FuturesAccount>> getAccount();
  Future<Either<Failure, List<FuturesPosition>>> getOpenPositions();
  Future<Either<Failure, FuturesPositionDetails>> getPositionDetails(String id);
  Future<Either<Failure, List<FuturesTrade>>> getLastTrades();
  Future<Either<Failure, FuturesQuote>> getQuote({
    required FuturesSide side,
    required Money size,
  });
  Future<Either<Failure, FuturesQuote>> getQuoteById(String quoteId);
  Future<Either<Failure, FuturesSubmit>> submit({
    required String requestId,
    required String quoteId,
  });
  Future<Either<Failure, SettlementStatus>> setTakeProfitStopLoss({
    required String requestId,
    required String positionId,
  });
  Future<Either<Failure, SettlementStatus>> closePosition({
    required String requestId,
    required String positionId,
  });
}
