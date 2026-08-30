import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/observe/settlement_breadcrumb.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/futures.dart';

final class FuturesLocalDataSource {
  final Map<String, FuturesQuote> quotes = {};
  final Set<String> requests = {};

  FuturesInstrument instrument() {
    return FuturesInstrument(
      pair: 'BTCUSDT',
      bid: Money.parse('78890.00', Currency.usdt),
      ask: Money.parse('78899.13', Currency.usdt),
      leverageTeasers: const ['10x', '25x', '50x', '100x'],
      freshness: QuoteFreshness.stale,
    );
  }

  FuturesAccount account() {
    return FuturesAccount(
      availableMargin: Money.parse('186.25', Currency.usdt),
      requiredMargin: Money.parse('50.00', Currency.usdt),
      riskTeaser: '27.78% placeholder',
      bonusTeaser: '21% placeholder',
    );
  }

  List<FuturesPosition> positions() {
    return [
      FuturesPosition(
        id: 'pos-pepe',
        pair: '1000PEPEUSDT',
        side: FuturesSide.long,
        size: Money.parse('1000', Currency.pepe),
        leverageTeaser: '100x',
      ),
    ];
  }

  FuturesPositionDetails? details(String id) {
    for (final position in positions()) {
      if (position.id == id) {
        return FuturesPositionDetails(
          position: position,
          pnl: Money.parse('-12.40', Currency.usdt),
          entry: Money.parse('0.00000850', Currency.usdt),
          mark: Money.parse('0.00000840', Currency.usdt),
          liquidation: Money.parse('0.00000100', Currency.usdt),
          lockedCollateral: Money.parse('10.00', Currency.usdt),
          maintenanceMargin: Money.parse('2.00', Currency.usdt),
          fundingTeaser: 'funding countdown placeholder',
          orderId: 'ord-pepe-1',
          markFreshness: QuoteFreshness.stale,
        );
      }
    }
    return null;
  }

  List<FuturesTrade> lastTrades() {
    return [
      FuturesTrade(
        side: FuturesSide.long,
        price: Money.parse('78899.13', Currency.usdt),
        size: Money.parse('0.01', Currency.btc),
      ),
      FuturesTrade(
        side: FuturesSide.short,
        price: Money.parse('78890.00', Currency.usdt),
        size: Money.parse('0.02', Currency.btc),
      ),
    ];
  }

  FuturesQuote quote({required FuturesSide side, required Money size}) {
    final q = FuturesQuote(
      quoteId: 'fut-${side.name}-${size.amount}',
      side: side,
      size: size,
      leverageTeaser: '100x',
      freshness: QuoteFreshness.stale,
    );
    quotes[q.quoteId] = q;
    return q;
  }

  FuturesSubmit submit({required String requestId, required String quoteId}) {
    if (requests.contains(requestId)) {
      return FuturesSubmit(
        requestId: requestId,
        settlement: SettlementStatus.inFlight,
      );
    }
    requests.add(requestId);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return FuturesSubmit(
      requestId: requestId,
      settlement: SettlementStatus.inFlight,
    );
  }

  SettlementStatus settleOnce(String requestId) {
    if (requests.contains(requestId)) {
      return SettlementStatus.inFlight;
    }
    requests.add(requestId);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SettlementStatus.inFlight;
  }
}
