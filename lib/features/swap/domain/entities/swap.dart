import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';

enum SwapWallet { savings, credit }

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

final class SwapQuote extends Equatable {
  const SwapQuote({
    required this.quoteId,
    required this.from,
    required this.to,
    required this.wallet,
    required this.freshness,
  });

  final String quoteId;
  final Money from;
  final Money to;
  final SwapWallet wallet;
  final QuoteFreshness freshness;

  SwapQuote copyWith({QuoteFreshness? freshness}) {
    return SwapQuote(
      quoteId: quoteId,
      from: from,
      to: to,
      wallet: wallet,
      freshness: freshness ?? this.freshness,
    );
  }

  @override
  List<Object?> get props => [quoteId, from, to, wallet, freshness];
}

final class SwapSubmit extends Equatable {
  const SwapSubmit({required this.requestId, required this.settlement});

  final String requestId;
  final SettlementStatus settlement;

  @override
  List<Object?> get props => [requestId, settlement];
}
