import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';

enum FundingRail { bank, receiveCrypto, buyCrypto }

enum FiatAccountStatus { none, inFlight, confirmed, failed, unknown }

final class FundingMethod extends Equatable {
  const FundingMethod({
    required this.rail,
    required this.label,
    required this.subtitle,
  });

  final FundingRail rail;
  final String label;
  final String subtitle;

  @override
  List<Object?> get props => [rail, label, subtitle];
}

final class FiatxAsset extends Equatable {
  const FiatxAsset({
    required this.currency,
    required this.feeTeaser,
  });

  final Currency currency;
  final String feeTeaser;

  @override
  List<Object?> get props => [currency, feeTeaser];
}

final class BankRail extends Equatable {
  const BankRail({
    required this.id,
    required this.label,
    required this.asset,
  });

  final String id;
  final String label;
  final Currency asset;

  @override
  List<Object?> get props => [id, label, asset];
}

final class FiatReceiveDetails extends Equatable {
  const FiatReceiveDetails({
    required this.asset,
    required this.rail,
    required this.beneficiary,
    required this.ibanOrAccount,
    required this.reference,
  });

  final Currency asset;
  final String rail;
  final String beneficiary;
  final String ibanOrAccount;
  final String reference;

  @override
  List<Object?> get props => [asset, rail, beneficiary, ibanOrAccount, reference];
}

final class ReceivableAsset extends Equatable {
  const ReceivableAsset({
    required this.currency,
    required this.network,
  });

  final Currency currency;
  final String network;

  @override
  List<Object?> get props => [currency, network];
}

final class ReceiveAddress extends Equatable {
  const ReceiveAddress({
    required this.currency,
    required this.network,
    required this.address,
    required this.qrUri,
  });

  final Currency currency;
  final String network;
  final String address;
  final String qrUri;

  @override
  List<Object?> get props => [currency, network, address, qrUri];
}

final class PurchasableAsset extends Equatable {
  const PurchasableAsset({
    required this.currency,
    required this.displayName,
    required this.price,
    required this.freshness,
  });

  final Currency currency;
  final String displayName;
  final Money price;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [currency, displayName, price, freshness];
}

final class BuyQuote extends Equatable {
  const BuyQuote({
    required this.quoteId,
    required this.spend,
    required this.receive,
    required this.cashbackTeaser,
    required this.freshness,
  });

  final String quoteId;
  final Money spend;
  final Money receive;
  final String cashbackTeaser;
  final QuoteFreshness freshness;

  BuyQuote copyWith({
    Money? receive,
    QuoteFreshness? freshness,
  }) {
    return BuyQuote(
      quoteId: quoteId,
      spend: spend,
      receive: receive ?? this.receive,
      cashbackTeaser: cashbackTeaser,
      freshness: freshness ?? this.freshness,
    );
  }

  @override
  List<Object?> get props => [quoteId, spend, receive, cashbackTeaser, freshness];
}

final class PaymentMethodOption extends Equatable {
  const PaymentMethodOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

final class BuySubmit extends Equatable {
  const BuySubmit({
    required this.requestId,
    required this.settlement,
  });

  final String requestId;
  final SettlementStatus settlement;

  @override
  List<Object?> get props => [requestId, settlement];
}
