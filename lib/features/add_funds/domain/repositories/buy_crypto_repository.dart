import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../entities/buy_crypto.dart';
import '../entities/bank_transfer.dart';

abstract class BuyCryptoRepository {
  Future<Either<Failure, List<PurchasableAsset>>> getAssets();

  Future<Either<Failure, List<PurchasableAsset>>> searchAssets(String query);

  Future<Either<Failure, BuyQuote>> getQuote({
    required Money fiatIn,
    required String cryptoCode,
    required PurchaseFrequency frequency,
  });

  Future<Either<Failure, BuyQuote>> getQuoteById(String quoteId);

  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods();

  Future<Either<Failure, List<PurchaseFrequency>>> getFrequencies();

  Future<Either<Failure, LinkCardSession>> startLinkCard({
    required String requestId,
  });

  Future<Either<Failure, List<EmptyBalance>>> getEmptyBalances();

  Future<Either<Failure, FundingSettlement>> submitBuy({
    required String requestId,
    required String quoteId,
    required String paymentMethodId,
    required Money amount,
    required PurchaseFrequency frequency,
  });
}
