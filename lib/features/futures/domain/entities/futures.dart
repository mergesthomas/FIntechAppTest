import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';

enum FuturesSide { long, short }

final class FuturesInstrument extends Equatable {
  const FuturesInstrument({
    required this.pair,
    required this.bid,
    required this.ask,
    required this.leverageTeasers,
    required this.freshness,
  });

  final String pair;
  final Money bid;
  final Money ask;
  final List<String> leverageTeasers;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [pair, bid, ask, leverageTeasers, freshness];
}

final class FuturesAccount extends Equatable {
  const FuturesAccount({
    required this.availableMargin,
    required this.requiredMargin,
    required this.riskTeaser,
    required this.bonusTeaser,
  });

  final Money availableMargin;
  final Money requiredMargin;
  final String riskTeaser;
  final String bonusTeaser;

  @override
  List<Object?> get props =>
      [availableMargin, requiredMargin, riskTeaser, bonusTeaser];
}

final class FuturesPosition extends Equatable {
  const FuturesPosition({
    required this.id,
    required this.pair,
    required this.side,
    required this.size,
    required this.leverageTeaser,
  });

  final String id;
  final String pair;
  final FuturesSide side;
  final Money size;
  final String leverageTeaser;

  @override
  List<Object?> get props => [id, pair, side, size, leverageTeaser];
}

final class FuturesPositionDetails extends Equatable {
  const FuturesPositionDetails({
    required this.position,
    required this.pnl,
    required this.entry,
    required this.mark,
    required this.liquidation,
    required this.lockedCollateral,
    required this.maintenanceMargin,
    required this.fundingTeaser,
    required this.orderId,
    required this.markFreshness,
  });

  final FuturesPosition position;
  final Money pnl;
  final Money entry;
  final Money mark;
  final Money liquidation;
  final Money lockedCollateral;
  final Money maintenanceMargin;
  final String fundingTeaser;
  final String orderId;
  final QuoteFreshness markFreshness;

  @override
  List<Object?> get props => [
        position,
        pnl,
        entry,
        mark,
        liquidation,
        lockedCollateral,
        maintenanceMargin,
        fundingTeaser,
        orderId,
        markFreshness,
      ];
}

final class FuturesQuote extends Equatable {
  const FuturesQuote({
    required this.quoteId,
    required this.side,
    required this.size,
    required this.leverageTeaser,
    required this.freshness,
  });

  final String quoteId;
  final FuturesSide side;
  final Money size;
  final String leverageTeaser;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [quoteId, side, size, leverageTeaser, freshness];
}

final class FuturesTrade extends Equatable {
  const FuturesTrade({
    required this.side,
    required this.price,
    required this.size,
  });

  final FuturesSide side;
  final Money price;
  final Money size;

  @override
  List<Object?> get props => [side, price, size];
}

final class FuturesSubmit extends Equatable {
  const FuturesSubmit({required this.requestId, required this.settlement});

  final String requestId;
  final SettlementStatus settlement;

  @override
  List<Object?> get props => [requestId, settlement];
}
