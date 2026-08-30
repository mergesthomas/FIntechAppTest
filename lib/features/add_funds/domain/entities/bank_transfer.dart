import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';

enum BankRail { ach, sepa, swift }

enum FiatAccountStatusKind { none, inFlight, confirmed, failed, unknown }

final class FiatxAsset extends Equatable {
  const FiatxAsset({
    required this.currency,
    required this.feeTeaserKey,
  });

  final Currency currency;

  /// Server copy key. Do not hard-code fee/legal strings in Domain.
  final String feeTeaserKey;

  @override
  List<Object?> get props => [currency, feeTeaserKey];
}

final class FiatAccountStatus extends Equatable {
  const FiatAccountStatus({
    required this.kind,
    this.requestId,
  });

  final FiatAccountStatusKind kind;
  final String? requestId;

  @override
  List<Object?> get props => [kind, requestId];
}

final class FiatReceiveDetails extends Equatable {
  const FiatReceiveDetails({
    required this.asset,
    required this.rail,
    required this.fields,
  });

  final Currency asset;
  final BankRail rail;

  /// Opaque labeled fields. Presentation copies; Domain never logs them.
  final Map<String, String> fields;

  @override
  List<Object?> get props => [asset, rail, fields];
}

final class BankFeeTier extends Equatable {
  const BankFeeTier({
    required this.threshold,
    required this.fee,
    required this.isFreeAboveThreshold,
  });

  final Money threshold;
  final Money fee;
  final bool isFreeAboveThreshold;

  @override
  List<Object?> get props => [threshold, fee, isFreeAboveThreshold];
}

final class BankFeeSchedule extends Equatable {
  const BankFeeSchedule({
    required this.asset,
    required this.rail,
    required this.tiers,
  });

  final Currency asset;
  final BankRail rail;
  final List<BankFeeTier> tiers;

  @override
  List<Object?> get props => [asset, rail, tiers];
}

final class FundingSettlement extends Equatable {
  const FundingSettlement({
    required this.requestId,
    required this.status,
  });

  final String requestId;
  final SettlementStatus status;

  @override
  List<Object?> get props => [requestId, status];
}
