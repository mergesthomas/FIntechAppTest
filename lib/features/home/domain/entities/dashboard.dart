import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/market/chart_sample.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';

enum DashboardPeriod { oneDay, oneWeek, oneMonth, oneYear, all }

ChartPeriod chartPeriodOf(DashboardPeriod period) {
  return switch (period) {
    DashboardPeriod.oneDay => ChartPeriod.oneDay,
    DashboardPeriod.oneWeek => ChartPeriod.oneWeek,
    DashboardPeriod.oneMonth => ChartPeriod.oneMonth,
    DashboardPeriod.oneYear => ChartPeriod.oneYear,
    DashboardPeriod.all => ChartPeriod.all,
  };
}

final class DashboardOverview extends Equatable {
  const DashboardOverview({
    required this.netWorth,
    required this.periodChangeRatio,
    required this.period,
    required this.chart,
    required this.freshness,
    required this.initials,
  });

  final Money netWorth;
  final Decimal periodChangeRatio;
  final DashboardPeriod period;
  final List<ChartSample> chart;
  final QuoteFreshness freshness;
  final String initials;

  @override
  List<Object?> get props => [
    netWorth,
    periodChangeRatio,
    period,
    chart,
    freshness,
    initials,
  ];
}

final class HoldingItem extends Equatable {
  const HoldingItem({
    required this.currency,
    required this.displayName,
    required this.quantity,
    required this.value,
    required this.change24hRatio,
    required this.sparkline,
    required this.freshness,
  });

  final Currency currency;
  final String displayName;
  final Money quantity;
  final Money value;
  final Decimal change24hRatio;
  final List<Decimal> sparkline;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [
    currency,
    displayName,
    quantity,
    value,
    change24hRatio,
    sparkline,
    freshness,
  ];
}

final class WatchlistItem extends Equatable {
  const WatchlistItem({
    required this.currency,
    required this.displayName,
    required this.price,
    required this.change24hRatio,
    required this.sparkline,
    required this.freshness,
  });

  final Currency currency;
  final String displayName;
  final Money price;
  final Decimal change24hRatio;
  final List<Decimal> sparkline;
  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [
    currency,
    displayName,
    price,
    change24hRatio,
    sparkline,
    freshness,
  ];
}

final class DashboardAlert extends Equatable {
  const DashboardAlert({
    required this.id,
    required this.copyKey,
    required this.dismissed,
  });

  final String id;
  final String copyKey;
  final bool dismissed;

  @override
  List<Object?> get props => [id, copyKey, dismissed];
}

final class DashboardPromo extends Equatable {
  const DashboardPromo({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
  });

  final String id;
  final String titleKey;
  final String bodyKey;

  @override
  List<Object?> get props => [id, titleKey, bodyKey];
}

final class NewsPreview extends Equatable {
  const NewsPreview({required this.id, required this.titleKey});

  final String id;
  final String titleKey;

  @override
  List<Object?> get props => [id, titleKey];
}
