import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/ledger/paper_ledger.dart';
import '../../../../core/ledger/paper_order.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/market/market_quote.dart';
import '../../../../core/market/quote_math.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/swap.dart';
import '../../domain/repositories/swap_repository.dart';
import '../datasources/swap_local_datasource.dart';

const _swapCurrencies = [
  Currency.usdc,
  Currency.eurx,
  Currency.btc,
  Currency.eth,
  Currency.doge,
  Currency.sol,
  Currency.xrp,
  Currency.pepe,
  Currency.bonk,
  Currency.usd,
  Currency.usdt,
];

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
      for (final currency in _swapCurrencies)
        SwapAsset(
          currency: currency,
          balance: _ledger.balance(book, currency),
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
  Stream<Either<Failure, SwapRate>> watchRate({
    required Currency from,
    required Currency to,
  }) async* {
    yield _rate(from, to);
    await for (final _ in _feed.quotes) {
      yield _rate(from, to);
    }
  }

  Either<Failure, SwapRate> _rate(Currency from, Currency to) {
    final toPerFrom = convertWithFeed(
      feed: _feed,
      from: Money.parse('1', from),
      to: to,
    );
    final fromPerTo = convertWithFeed(
      feed: _feed,
      from: Money.parse('1', to),
      to: from,
    );
    return toPerFrom.flatMap((out) {
      return fromPerTo.map((unit) {
        return SwapRate(
          fromPerTo: unit.to,
          toPerFrom: out.to,
          freshness: combineFreshness(unit.freshness, out.freshness),
        );
      });
    });
  }

  @override
  Future<Either<Failure, SwapQuote>> getQuote(SwapQuoteRequest request) async {
    final converted = convertWithFeed(
      feed: _feed,
      from: request.amount,
      to: request.to,
    );
    final unit = convertWithFeed(
      feed: _feed,
      from: Money.parse('1', request.to),
      to: request.from,
    );
    return converted.flatMap((value) {
      return unit.map((priced) {
        final quote = SwapQuote(
          quoteId:
              'swap-${request.from.code}-${request.to.code}-${request.amount.amount}-${request.type.name}',
          from: request.amount,
          to: value.to,
          wallet: SwapWallet.savings,
          freshness: combineFreshness(value.freshness, priced.freshness),
          type: request.type,
          rateFromPerTo: priced.to,
          limitPrice: request.limitPrice,
          takeProfit: request.takeProfit,
          stopLoss: request.stopLoss,
        );
        return _local.store(quote);
      });
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
    final venue = switch (quote.type) {
      SwapOrderType.instant => PaperVenue.market,
      SwapOrderType.limit => PaperVenue.limit,
      SwapOrderType.trigger => PaperVenue.trigger,
    };
    final order = PaperOrder(
      id: 'ord-$requestId',
      requestId: requestId,
      pair: '${quote.from.currency.code}/${quote.to.currency.code}',
      side: PaperSide.sell,
      status: PaperOrderStatus.open,
      amount: quote.from,
      wallet: wallet.name,
      venue: venue,
      pay: quote.from.currency,
      receive: quote.to.currency,
      limitPrice: quote.limitPrice,
      takeProfit: quote.takeProfit,
      stopLoss: quote.stopLoss,
    );
    if (quote.type == SwapOrderType.instant) {
      final posted = await _ledger.post(
        requestId: requestId,
        lines: [
          LedgerLine(
            book: _book(wallet),
            delta: Money.zero(quote.from.currency) - quote.from,
          ),
          LedgerLine(book: _book(wallet), delta: quote.to),
        ],
        order: order,
      );
      return posted.map(
        (status) => SwapSubmit(
          requestId: requestId,
          settlement: status,
          venue: venue,
        ),
      );
    }
    final placed = await _ledger.placeHold(
      requestId: requestId,
      hold: quote.from,
      book: _book(wallet),
      order: order,
    );
    return placed.map(
      (status) => SwapSubmit(
        requestId: requestId,
        settlement: status,
        venue: venue,
      ),
    );
  }
}
