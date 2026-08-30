import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';

enum PurchaseFrequency { oneTime, scheduled }

enum PaymentMethodKind { card, applePay, linkCard, fiatxBalance }

final class PurchasableAsset extends Equatable {
  const PurchasableAsset({
    required this.currency,
    required this.displayName,
    required this.price,
    required this.change24hRatio,
    required this.freshness,
  });

  final Currency currency;
  final String displayName;
  final Money price;

  /// Ratio, not a [double] percent (e.g. 0.0154 for +1.54%).
  final Decimal change24hRatio;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props =>
      [currency, displayName, price, change24hRatio, freshness];
}

final class BuyQuote extends Equatable {
  const BuyQuote({
    required this.quoteId,
    required this.fiatIn,
    required this.cryptoOut,
    required this.cashbackCopyKey,
    required this.freshness,
  });

  final String quoteId;
  final Money fiatIn;
  final Money cryptoOut;
  final String cashbackCopyKey;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props =>
      [quoteId, fiatIn, cryptoOut, cashbackCopyKey, freshness];
}

final class PaymentMethod extends Equatable {
  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
    required this.isEligible,
  });

  final String id;
  final PaymentMethodKind kind;
  final String label;
  final bool isEligible;

  @override
  List<Object?> get props => [id, kind, label, isEligible];
}

final class EmptyBalance extends Equatable {
  const EmptyBalance({
    required this.currency,
    required this.canRestore,
  });

  final Currency currency;
  final bool canRestore;

  @override
  List<Object?> get props => [currency, canRestore];
}

final class LinkCardSession extends Equatable {
  const LinkCardSession({
    required this.processorSessionId,
    required this.requestId,
  });

  final String processorSessionId;
  final String requestId;

  @override
  List<Object?> get props => [processorSessionId, requestId];
}
