import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../entities/funding.dart';

abstract class FundingRepository {
  Future<Either<Failure, List<FundingMethod>>> getMethods();

  Future<Either<Failure, List<FiatxAsset>>> getFiatxAssets();

  Future<Either<Failure, List<BankRail>>> getBankRails(Currency asset);

  Future<Either<Failure, FiatAccountStatus>> getFiatAccountStatus();

  Future<Either<Failure, Unit>> acceptFiatAccountTerms();

  Future<Either<Failure, SettlementStatus>> createPersonalUsdAccount({
    required String requestId,
  });

  Future<Either<Failure, FiatReceiveDetails>> getFiatReceiveDetails({
    required Currency asset,
    required String rail,
  });

  Future<Either<Failure, String>> getBankTransferFeeSchedule(Currency asset);

  Future<Either<Failure, List<ReceivableAsset>>> getReceivableAssets(String query);

  Future<Either<Failure, ReceiveAddress>> getReceiveAddress(Currency currency);

  Future<Either<Failure, List<PurchasableAsset>>> getPurchasableAssets(
    String query,
  );

  Future<Either<Failure, BuyQuote>> getBuyQuote({
    required Currency asset,
    required Money spend,
  });

  Future<Either<Failure, BuyQuote>> getBuyQuoteById(String quoteId);

  Future<Either<Failure, List<PaymentMethodOption>>> getPaymentMethods();

  Future<Either<Failure, List<String>>> getPurchaseFrequencies();

  Future<Either<Failure, BuySubmit>> submitBuy({
    required String requestId,
    required String quoteId,
    required String paymentMethodId,
    required Money amount,
    required String frequency,
  });
}
