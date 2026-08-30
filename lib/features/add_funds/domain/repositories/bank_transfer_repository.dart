import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/bank_transfer.dart';

abstract class BankTransferRepository {
  Future<Either<Failure, List<FiatxAsset>>> getFiatxAssets();

  Future<Either<Failure, List<BankRail>>> getRails(Currency asset);

  Future<Either<Failure, FiatAccountStatus>> getAccountStatus(Currency asset);

  Future<Either<Failure, void>> acceptTerms({
    required Currency asset,
    required String requestId,
  });

  Future<Either<Failure, FundingSettlement>> createPersonalUsdAccount({
    required String requestId,
  });

  Future<Either<Failure, FiatReceiveDetails>> getReceiveDetails({
    required Currency asset,
    required BankRail rail,
  });

  Future<Either<Failure, BankFeeSchedule>> getFeeSchedule({
    required Currency asset,
    required BankRail rail,
  });
}
