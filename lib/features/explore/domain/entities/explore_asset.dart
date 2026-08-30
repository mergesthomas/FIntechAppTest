import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';

final class ExploreAsset extends Equatable {
  const ExploreAsset({
    required this.currency,
    required this.name,
    required this.price,
    required this.change24h,
    required this.freshness,
  });

  final Currency currency;
  final String name;
  final Money price;
  final Decimal change24h;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [currency, name, price, change24h, freshness];
}
