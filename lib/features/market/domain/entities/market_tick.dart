import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/money.dart';

final class MarketTick extends Equatable {
  const MarketTick({
    required this.price,
    required this.last,
    required this.change24h,
    required this.freshness,
    required this.at,
  });

  final Money price;
  final Decimal last;
  final Decimal change24h;
  final QuoteFreshness freshness;
  final DateTime at;

  @override
  List<Object?> get props => [price, last, change24h, freshness, at];
}
