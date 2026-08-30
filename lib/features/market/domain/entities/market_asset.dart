import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/market/price_series.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';

final class MarketAsset extends Equatable {
  const MarketAsset({
    required this.currency,
    required this.name,
    required this.price,
    required this.change24h,
    required this.freshness,
    required this.chart,
  });

  final Currency currency;
  final String name;
  final Money price;
  final Decimal change24h;
  final QuoteFreshness freshness;
  final PriceSeries chart;

  MarketAsset copyWith({PriceSeries? chart}) {
    return MarketAsset(
      currency: currency,
      name: name,
      price: price,
      change24h: change24h,
      freshness: freshness,
      chart: chart ?? this.chart,
    );
  }

  @override
  List<Object?> get props =>
      [currency, name, price, change24h, freshness, chart];
}
