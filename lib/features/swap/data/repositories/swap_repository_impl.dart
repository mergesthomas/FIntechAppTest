import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/ledger/paper_ledger.dart';
import '../../../../core/ledger/paper_order.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/quote_math.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/swap.dart';
import '../../domain/repositories/swap_repository.dart';
import '../datasources/swap_local_datasource.dart';

final class SwapRepositoryImpl implements SwapRepository {
  SwapRepositoryImpl(
    this._local, {
    required MarketFeed feed,
    required PaperLedger ledger,
  })  : _feed = feed,
        _ledger = ledger;

  final SwapLocalDataSource _local;
  final MarketFeed _feed;
  final PaperLedger _ledger;

  LedgerBook _book(SwapWallet wallet) {
    return wallet == SwapWallet.credit ? LedgerBook.credit : LedgerBook.savings;
  }

  @override
  Future<Either<Failure, List<SwapWallet>>> getWallets() async {
    return Either.right(_local.wallets());
  }

  @override
  Future<Either<Failure, List<SwapAsset>>> searchAssets(String query) async {
    final book = LedgerBook.savings;
    final all = [
      SwapAsset(
        currency: Currency.nexo,
        balance: _ledger.balance(book, Currency.nexo),
      ),
      SwapAsset(
        currency: Currency.eurx,
        balance: _ledger.balance(book, Currency.eurx),
      ),
      SwapAsset(
        currency: Currency.btc,
        balance: _ledger.balance(book, Currency.btc),
      ),
    ];
    if (query.isEmpty) {
      return Either.right(all);
    }
    final q = query.toLowerCase();
    return Either.right(
      all.where((a) => a.currency.code.toLowerCase().contains(q)).toList(),
    );
  }

  @override
  Future<Either<Failure, SwapQuote>> getQuote({
    required Currency from,
    required Currency to,
    required Money amount,
    required SwapWallet wallet,
  }) async {
    final converted = convertWithFeed(feed: _feed, from: amount, to: to);
    return converted.map((value) {
      final quote = SwapQuote(
        quoteId: 'swap-${from.code}-${to.code}-${amount.amount}',
        from: amount,
        to: value.to,
        wallet: wallet,
        freshness: value.freshness,
      );
      _local.quotes[quote.quoteId] = quote;
      return quote;
    });
  }

  @override
  Future<Either<Failure, SwapQuote>> getQuoteById(String quoteId) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    final converted = convertWithFeed(
      feed: _feed,
      from: quote.from,
      to: quote.to.currency,
    );
    return converted.map(
      (value) => quote.copyWith(freshness: value.freshness),
    );
  }

  @override
  Future<Either<Failure, SwapSubmit>> submit({
    required String requestId,
    required String quoteId,
    required SwapWallet wallet,
  }) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    final posted = await _ledger.post(
      requestId: requestId,
      lines: [
        LedgerLine(
          book: _book(wallet),
          delta: Money.zero(quote.from.currency) - quote.from,
        ),
        LedgerLine(book: _book(wallet), delta: quote.to),
      ],
      order: PaperOrder(
        id: 'ord-$requestId',
        requestId: requestId,
        pair: '${quote.from.currency.code}/${quote.to.currency.code}',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: quote.from,
        wallet: wallet.name,
        venue: PaperVenue.market,
      ),
    );
    return posted.map(
      (status) => SwapSubmit(requestId: requestId, settlement: status),
    );
  }
}
