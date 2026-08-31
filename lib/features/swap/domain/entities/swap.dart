import 'package:equatable/equatable.dart';

import '../../../../core/ledger/paper_order.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';

enum SwapWallet { savings, credit }

enum SwapOrderType { instant, limit, trigger }

final class SwapAsset extends Equatable {
  const SwapAsset({
    required this.currency,
    required this.balance,
  });

  final Currency currency;
  final Money balance;

  @override
  List<Object?> get props => [currency, balance];
}

final class SwapRate extends Equatable {
  const SwapRate({
    required this.fromPerTo,
    required this.toPerFrom,
    required this.freshness,
  });

  /// Price of 1 [to] unit in the [from] currency.
  final Money fromPerTo;

  /// Amount of [to] received for 1 [from].
  final Money toPerFrom;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [fromPerTo, toPerFrom, freshness];
}

final class SwapQuoteRequest extends Equatable {
  const SwapQuoteRequest({
    required this.from,
    required this.to,
    required this.amount,
    required this.type,
    this.limitPrice,
    this.takeProfit,
    this.stopLoss,
  });

  final Currency from;
  final Currency to;
  final Money amount;
  final SwapOrderType type;
  final Money? limitPrice;
  final Money? takeProfit;
  final Money? stopLoss;

  @override
  List<Object?> get props =>
      [from, to, amount, type, limitPrice, takeProfit, stopLoss];
}

final class SwapQuote extends Equatable {
  const SwapQuote({
    required this.quoteId,
    required this.from,
    required this.to,
    required this.wallet,
    required this.freshness,
    required this.type,
    required this.rateFromPerTo,
    this.limitPrice,
    this.takeProfit,
    this.stopLoss,
  });

  final String quoteId;
  final Money from;
  final Money to;
  final SwapWallet wallet;
  final QuoteFreshness freshness;
  final SwapOrderType type;
  final Money rateFromPerTo;
  final Money? limitPrice;
  final Money? takeProfit;
  final Money? stopLoss;

  SwapQuote copyWith({QuoteFreshness? freshness}) {
    return SwapQuote(
      quoteId: quoteId,
      from: from,
      to: to,
      wallet: wallet,
      freshness: freshness ?? this.freshness,
      type: type,
      rateFromPerTo: rateFromPerTo,
      limitPrice: limitPrice,
      takeProfit: takeProfit,
      stopLoss: stopLoss,
    );
  }

  @override
  List<Object?> get props => [
        quoteId,
        from,
        to,
        wallet,
        freshness,
        type,
        rateFromPerTo,
        limitPrice,
        takeProfit,
        stopLoss,
      ];
}

final class SwapSubmit extends Equatable {
  const SwapSubmit({
    required this.requestId,
    required this.settlement,
    required this.venue,
  });

  final String requestId;
  final SettlementStatus settlement;
  final PaperVenue venue;

  @override
  List<Object?> get props => [requestId, settlement, venue];
}
