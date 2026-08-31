import 'package:decimal/decimal.dart';

import '../market/chart_sample.dart';
import '../market/price_series.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'ledger_lot.dart';

DateTime chartWindowStart({
  required ChartPeriod period,
  required DateTime end,
  DateTime? firstActivity,
}) {
  final utc = end.toUtc();
  return switch (period) {
    ChartPeriod.oneDay => utc.subtract(const Duration(days: 1)),
    ChartPeriod.oneWeek => utc.subtract(const Duration(days: 7)),
    ChartPeriod.oneMonth => utc.subtract(const Duration(days: 30)),
    ChartPeriod.oneYear => utc.subtract(const Duration(days: 365)),
    ChartPeriod.all =>
      (firstActivity ?? utc.subtract(const Duration(days: 365 * 3))).toUtc(),
  };
}

List<DateTime> portfolioSampleTimes({
  required DateTime start,
  required DateTime end,
  required int count,
  required List<DateTime> events,
  bool includePreStart = false,
}) {
  final from = start.toUtc();
  final to = end.toUtc();
  if (to.isBefore(from)) {
    return [to];
  }
  final times = <int, DateTime>{};
  void add(DateTime value) {
    final utc = value.toUtc();
    times[utc.millisecondsSinceEpoch] = utc;
  }

  if (includePreStart) {
    add(from.subtract(const Duration(seconds: 1)));
  }
  add(from);
  add(to);
  final spanMs = to.difference(from).inMilliseconds;
  final steps = count <= 1 ? 1 : count - 1;
  if (spanMs > 0) {
    for (var i = 0; i < count; i++) {
      add(from.add(Duration(milliseconds: spanMs * i ~/ steps)));
    }
  }
  for (final event in events) {
    final utc = event.toUtc();
    if (!utc.isBefore(from) && !utc.isAfter(to)) {
      add(utc);
    }
  }
  final list = times.values.toList()..sort();
  return list;
}

Decimal quantityAt({
  required Money current,
  required List<LedgerLot> lots,
  required DateTime at,
}) {
  var qty = current.amount;
  final when = at.toUtc();
  for (final lot in lots) {
    if (lot.currency == current.currency && lot.at.toUtc().isAfter(when)) {
      qty -= lot.quantity;
    }
  }
  return qty;
}

List<ChartSample> buildPortfolioChart({
  required List<LedgerLot> lots,
  required List<Money> balances,
  required List<DateTime> times,
  required Decimal Function(Currency currency, DateTime at) usdRateAt,
}) {
  final currencies = <String, Currency>{
    for (final held in balances) held.currency.code: held.currency,
    for (final lot in lots) lot.currency.code: lot.currency,
  };
  return [
    for (final at in times)
      ChartSample(
        value: Money.fromDecimal(
          _valueAt(
            currencies: currencies.values,
            balances: balances,
            lots: lots,
            at: at,
            usdRateAt: usdRateAt,
          ),
          Currency.usd,
        ),
        at: at,
      ),
  ];
}

Decimal seriesRateAt({
  required List<Decimal> closes,
  required DateTime start,
  required DateTime end,
  required DateTime at,
  required Decimal fallback,
}) {
  if (closes.isEmpty) {
    return fallback;
  }
  final from = start.toUtc();
  final to = end.toUtc();
  final when = at.toUtc();
  if (when.isBefore(from)) {
    return closes.first;
  }
  if (!when.isBefore(to)) {
    return closes.last;
  }
  final spanMs = to.difference(from).inMilliseconds;
  if (spanMs <= 0 || closes.length == 1) {
    return closes.last;
  }
  final elapsed = when.difference(from).inMilliseconds;
  final index = (elapsed * (closes.length - 1)) ~/ spanMs;
  if (index <= 0) {
    return closes.first;
  }
  if (index >= closes.length) {
    return closes.last;
  }
  return closes[index];
}

Decimal _valueAt({
  required Iterable<Currency> currencies,
  required List<Money> balances,
  required List<LedgerLot> lots,
  required DateTime at,
  required Decimal Function(Currency currency, DateTime at) usdRateAt,
}) {
  var total = Decimal.zero;
  for (final currency in currencies) {
    final current = _current(balances, currency);
    final qty = quantityAt(current: current, lots: lots, at: at);
    if (qty == Decimal.zero) {
      continue;
    }
    total += qty * usdRateAt(currency, at);
  }
  return total;
}

Money _current(List<Money> balances, Currency currency) {
  for (final held in balances) {
    if (held.currency == currency) {
      return held;
    }
  }
  return Money.zero(currency);
}
