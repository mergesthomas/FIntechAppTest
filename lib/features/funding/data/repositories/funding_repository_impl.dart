import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/ledger/paper_ledger.dart';
import '../../../../core/ledger/paper_order.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/quote_math.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/funding.dart';
import '../../domain/repositories/funding_repository.dart';
import '../datasources/funding_local_datasource.dart';

final class FundingRepositoryImpl implements FundingRepository {
  FundingRepositoryImpl(
    this._local, {
    required MarketFeed feed,
    required PaperLedger ledger,
  })  : _feed = feed,
        _ledger = ledger;

  final FundingLocalDataSource _local;
  final MarketFeed _feed;
  final PaperLedger _ledger;

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
    final listed = _local.purchasable(query);
    return Either.right([
      for (final asset in listed)
        PurchasableAsset(
          currency: asset.currency,
          displayName: asset.displayName,
          price: _feed.usdPrice(asset.currency) ?? asset.price,
          freshness: _feed.quoteFor(asset.currency)?.freshness ?? asset.freshness,
        ),
    ]);
  }

  @override
  Future<Either<Failure, BuyQuote>> getBuyQuote({
    required Currency asset,
    required Money spend,
  }) async {
    final converted = buyWithUsd(feed: _feed, asset: asset, spend: spend);
    return converted.map((value) {
      final quote = BuyQuote(
        quoteId: 'quote-${asset.code}-${spend.amount}',
        spend: spend,
        receive: value.receive,
        cashbackTeaser: 'Cashback teaser — placeholder',
        freshness: value.freshness,
      );
      _local.quotes[quote.quoteId] = quote;
      return quote;
    });
  }

  @override
  Future<Either<Failure, BuyQuote>> getBuyQuoteById(String quoteId) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    final converted = buyWithUsd(
      feed: _feed,
      asset: quote.receive.currency,
      spend: quote.spend,
    );
    return converted.map((value) => quote.copyWith(freshness: value.freshness));
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
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    final posted = await _ledger.post(
      requestId: requestId,
      lines: [
        LedgerLine(
          book: LedgerBook.savings,
          delta: Money.zero(quote.spend.currency) - quote.spend,
        ),
        LedgerLine(book: LedgerBook.savings, delta: quote.receive),
      ],
      order: PaperOrder(
        id: 'ord-$requestId',
        requestId: requestId,
        pair: '${quote.receive.currency.code}/USD',
        side: PaperSide.buy,
        status: PaperOrderStatus.open,
        amount: quote.receive,
        wallet: paymentMethodId,
        venue: PaperVenue.market,
      ),
    );
    return posted.map(
      (status) => BuySubmit(requestId: requestId, settlement: status),
    );
  }
}
