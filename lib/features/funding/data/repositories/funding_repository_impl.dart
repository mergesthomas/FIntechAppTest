import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/funding.dart';
import '../../domain/repositories/funding_repository.dart';
import '../datasources/funding_local_datasource.dart';

final class FundingRepositoryImpl implements FundingRepository {
  FundingRepositoryImpl(this._local);

  final FundingLocalDataSource _local;

  @override
  Future<Either<Failure, List<FundingMethod>>> getMethods() async {
    return Either.right(_local.methods());
  }

  @override
  Future<Either<Failure, List<FiatxAsset>>> getFiatxAssets() async {
    return Either.right(_local.fiatxAssets());
  }

  @override
  Future<Either<Failure, List<BankRail>>> getBankRails(Currency asset) async {
    return Either.right(_local.bankRails(asset));
  }

  @override
  Future<Either<Failure, FiatAccountStatus>> getFiatAccountStatus() async {
    return Either.right(_local.accountStatus);
  }

  @override
  Future<Either<Failure, Unit>> acceptFiatAccountTerms() async {
    _local.termsAccepted = true;
    return Either.right(unit);
  }

  @override
  Future<Either<Failure, SettlementStatus>> createPersonalUsdAccount({
    required String requestId,
  }) async {
    if (!_local.termsAccepted) {
      return Either.left(const ValidationFailure('terms_required'));
    }
    return Either.right(_local.createUsdAccount(requestId));
  }

  @override
  Future<Either<Failure, FiatReceiveDetails>> getFiatReceiveDetails({
    required Currency asset,
    required String rail,
  }) async {
    return Either.right(_local.receiveDetails(asset, rail));
  }

  @override
  Future<Either<Failure, String>> getBankTransferFeeSchedule(
    Currency asset,
  ) async {
    return Either.right(_local.feeSchedule(asset));
  }

  @override
  Future<Either<Failure, List<ReceivableAsset>>> getReceivableAssets(
    String query,
  ) async {
    return Either.right(_local.receivable(query));
  }

  @override
  Future<Either<Failure, ReceiveAddress>> getReceiveAddress(
    Currency currency,
  ) async {
    return Either.right(_local.receiveAddress(currency));
  }

  @override
  Future<Either<Failure, List<PurchasableAsset>>> getPurchasableAssets(
    String query,
  ) async {
    return Either.right(_local.purchasable(query));
  }

  @override
  Future<Either<Failure, BuyQuote>> getBuyQuote({
    required Currency asset,
    required Money spend,
  }) async {
    return Either.right(_local.buyQuote(asset: asset, spend: spend));
  }

  @override
  Future<Either<Failure, BuyQuote>> getBuyQuoteById(String quoteId) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    return Either.right(quote);
  }

  @override
  Future<Either<Failure, List<PaymentMethodOption>>> getPaymentMethods() async {
    return Either.right(_local.paymentMethods());
  }

  @override
  Future<Either<Failure, List<String>>> getPurchaseFrequencies() async {
    return Either.right(_local.frequencies());
  }

  @override
  Future<Either<Failure, BuySubmit>> submitBuy({
    required String requestId,
    required String quoteId,
    required String paymentMethodId,
    required Money amount,
    required String frequency,
  }) async {
    return Either.right(
      _local.submitBuy(
        requestId: requestId,
        quoteId: quoteId,
        paymentMethodId: paymentMethodId,
        amount: amount,
        frequency: frequency,
      ),
    );
  }
}
