import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';

final class ReceivableAsset extends Equatable {
  const ReceivableAsset({
    required this.currency,
    required this.displayName,
  });

  final Currency currency;
  final String displayName;

  @override
  List<Object?> get props => [currency, displayName];
}

final class ReceiveAddress extends Equatable {
  const ReceiveAddress({
    required this.asset,
    required this.network,
    required this.address,
    required this.qrPayload,
  });

  final Currency asset;
  final String network;
  final String address;
  final String qrPayload;

  @override
  List<Object?> get props => [asset, network, address, qrPayload];
}

final class AssetFundingTeasers extends Equatable {
  const AssetFundingTeasers({
    required this.asset,
    required this.earnCopyKey,
    required this.borrowCopyKey,
  });

  final Currency asset;

  /// Placeholder keys until compliance provides copy.
  final String earnCopyKey;
  final String borrowCopyKey;

  @override
  List<Object?> get props => [asset, earnCopyKey, borrowCopyKey];
}
