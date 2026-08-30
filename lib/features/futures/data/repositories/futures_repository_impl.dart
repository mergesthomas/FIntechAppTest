import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/ledger/paper_ledger.dart';
import '../../../../core/ledger/paper_order.dart';
import '../../../../core/market/market_feed.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/futures.dart';
import '../../domain/repositories/futures_repository.dart';
import '../datasources/futures_local_datasource.dart';

final class FuturesRepositoryImpl implements FuturesRepository {
  FuturesRepositoryImpl(
    this._local, {
    required MarketFeed feed,
    required PaperLedger ledger,
  })  : _feed = feed,
        _ledger = ledger;

  final FuturesLocalDataSource _local;
  final MarketFeed _feed;
  final PaperLedger _ledger;

  @override
  Future<Either<Failure, FuturesInstrument>> getInstrument() async {
    final fixture = _local.instrument();
    final tick = _feed.quoteFor(Currency.btc);
    if (tick == null) {
      return Either.right(fixture);
    }
    return Either.right(
      FuturesInstrument(
        pair: fixture.pair,
        bid: tick.price,
        ask: tick.price,
        leverageTeasers: fixture.leverageTeasers,
        freshness: tick.freshness,
      ),
    );
  }

  @override
  Future<Either<Failure, FuturesAccount>> getAccount() async {
    final fixture = _local.account();
    return Either.right(
      FuturesAccount(
        availableMargin: _ledger.balance(LedgerBook.futures, Currency.usdt),
        requiredMargin: fixture.requiredMargin,
        riskTeaser: fixture.riskTeaser,
        bonusTeaser: fixture.bonusTeaser,
      ),
    );
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
    final tick = _feed.quoteFor(Currency.pepe) ?? _feed.quoteFor(Currency.btc);
    if (tick == null) {
      return Either.right(details);
    }
    return Either.right(
      FuturesPositionDetails(
        position: details.position,
        pnl: details.pnl,
        entry: details.entry,
        mark: tick.price,
        liquidation: details.liquidation,
        lockedCollateral: details.lockedCollateral,
        maintenanceMargin: details.maintenanceMargin,
        fundingTeaser: details.fundingTeaser,
        orderId: details.orderId,
        markFreshness: tick.freshness,
      ),
    );
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
    final tick = _feed.quoteFor(Currency.btc);
    final quote = FuturesQuote(
      quoteId: 'fut-${side.name}-${size.amount}',
      side: side,
      size: size,
      leverageTeaser: '100x',
      freshness: tick?.freshness ?? _feed.connection,
    );
    _local.quotes[quote.quoteId] = quote;
    return Either.right(quote);
  }

  @override
  Future<Either<Failure, FuturesQuote>> getQuoteById(String quoteId) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    final tick = _feed.quoteFor(Currency.btc);
    return Either.right(
      quote.copyWith(freshness: tick?.freshness ?? _feed.connection),
    );
  }

  @override
  Future<Either<Failure, FuturesSubmit>> submit({
    required String requestId,
    required String quoteId,
  }) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    final mark = _feed.usdPrice(Currency.btc);
    if (mark == null || mark.amount == Decimal.zero) {
      return Either.left(const StaleQuoteFailure());
    }
    final notional = quote.size.amount * mark.amount;
    final margin = Money.fromDecimal(
      (notional / Decimal.fromInt(100)).toDecimal(scaleOnInfinitePrecision: 8),
      Currency.usdt,
    );
    final posted = await _ledger.post(
      requestId: requestId,
      lines: [
        LedgerLine(
          book: LedgerBook.futures,
          delta: Money.zero(Currency.usdt) - margin,
        ),
      ],
      order: PaperOrder(
        id: 'ord-$requestId',
        requestId: requestId,
        pair: 'BTCUSDT',
        side: quote.side == FuturesSide.long ? PaperSide.buy : PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: quote.size,
        wallet: 'futures',
        venue: PaperVenue.market,
      ),
    );
    return posted.map(
      (status) => FuturesSubmit(requestId: requestId, settlement: status),
    );
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
    final details = _local.details(positionId);
    final release = details?.lockedCollateral ?? Money.parse('10', Currency.usdt);
    final posted = await _ledger.post(
      requestId: requestId,
      lines: [
        LedgerLine(book: LedgerBook.futures, delta: release),
      ],
      order: PaperOrder(
        id: 'ord-$requestId',
        requestId: requestId,
        pair: details?.position.pair ?? 'BTCUSDT',
        side: PaperSide.sell,
        status: PaperOrderStatus.open,
        amount: details?.position.size ?? Money.parse('0.01', Currency.btc),
        wallet: 'futures',
        venue: PaperVenue.market,
      ),
    );
    return posted;
  }
}
