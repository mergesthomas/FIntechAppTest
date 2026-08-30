import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/observe/settlement_breadcrumb.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/swap.dart';

final class SwapLocalDataSource {
  final Map<String, SwapQuote> quotes = {};
  final Set<String> requests = {};

  List<SwapWallet> wallets() => SwapWallet.values;

  List<SwapAsset> assets(String query) {
    final all = [
      SwapAsset(
        currency: Currency.nexo,
        balance: Money.parse('120.00', Currency.nexo),
      ),
      SwapAsset(
        currency: Currency.eurx,
        balance: Money.parse('-1.16', Currency.eurx),
      ),
      SwapAsset(
        currency: Currency.btc,
        balance: Money.parse('0.15', Currency.btc),
      ),
    ];
    if (query.isEmpty) {
      return all;
    }
    final q = query.toLowerCase();
    return all
        .where((a) => a.currency.code.toLowerCase().contains(q))
        .toList();
  }

  SwapQuote quote({
    required Currency from,
    required Currency to,
    required Money amount,
    required SwapWallet wallet,
  }) {
    final q = SwapQuote(
      quoteId: 'swap-${from.code}-${to.code}-${amount.amount}',
      from: amount,
      to: Money.parse('1.00', to),
      wallet: wallet,
      freshness: QuoteFreshness.stale,
    );
    quotes[q.quoteId] = q;
    return q;
  }

  SwapSubmit submit({
    required String requestId,
    required String quoteId,
    required SwapWallet wallet,
  }) {
    if (requests.contains(requestId)) {
      return SwapSubmit(
        requestId: requestId,
        settlement: SettlementStatus.inFlight,
      );
    }
    requests.add(requestId);
    logSettlementBreadcrumb(
      requestId: requestId,
      status: SettlementStatus.inFlight,
    );
    return SwapSubmit(
      requestId: requestId,
      settlement: SettlementStatus.inFlight,
    );
  }
}
