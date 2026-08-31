import 'package:decimal/decimal.dart';

import '../clock/app_clock.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'depth_book.dart';
import 'quote_freshness.dart';

/// Parses Binance REST / partial-book / diff depth. Prices stay strings.
DepthBook? parseBinanceDepth(
  Map<String, dynamic> json, {
  required AppClock clock,
  String? symbol,
  QuoteFreshness freshness = QuoteFreshness.live,
  int depth = 20,
}) {
  final resolved = (symbol ?? json['s'] as String? ?? '').trim();
  if (resolved.isEmpty) {
    return null;
  }
  final bids = _levels(
    json['bids'] ?? json['b'],
    sideIsBid: true,
  );
  final asks = _levels(
    json['asks'] ?? json['a'],
    sideIsBid: false,
  );
  if (bids.isEmpty && asks.isEmpty) {
    return null;
  }
  return DepthBook(
    symbol: resolved.toUpperCase(),
    bids: bids.take(depth).toList(growable: false),
    asks: asks.take(depth).toList(growable: false),
    freshness: freshness,
    updatedAt: clock.now(),
  );
}

String? symbolFromDepthStream(String stream) {
  final at = stream.indexOf('@');
  if (at <= 0) {
    return null;
  }
  return stream.substring(0, at).toUpperCase();
}

List<DepthLevel> _levels(Object? raw, {required bool sideIsBid}) {
  if (raw is! List) {
    return const [];
  }
  final parsed = <DepthLevel>[];
  for (final row in raw) {
    final level = _level(row);
    if (level != null) {
      parsed.add(level);
    }
  }
  parsed.sort(
    (a, b) => sideIsBid
        ? b.price.amount.compareTo(a.price.amount)
        : a.price.amount.compareTo(b.price.amount),
  );
  return parsed;
}

DepthLevel? _level(Object? raw) {
  if (raw is! List || raw.length < 2) {
    return null;
  }
  final priceRaw = raw[0];
  final qtyRaw = raw[1];
  if (priceRaw is! String || qtyRaw is! String) {
    return null;
  }
  if (priceRaw.isEmpty || qtyRaw.isEmpty) {
    return null;
  }
  try {
    final quantity = Decimal.parse(qtyRaw);
    if (quantity <= Decimal.zero) {
      return null;
    }
    return DepthLevel(
      price: Money.parse(priceRaw, Currency.usdt),
      quantity: quantity,
    );
  } on FormatException {
    return null;
  }
}
