import 'package:decimal/decimal.dart';

/// Parses Binance kline rows. Close (index 4) stays a string → [Decimal].
List<Decimal> parseBinanceKlineCloses(List<dynamic> rows) {
  final closes = <Decimal>[];
  for (final row in rows) {
    if (row is! List || row.length < 5) {
      continue;
    }
    final close = row[4];
    if (close is String && close.isNotEmpty) {
      closes.add(Decimal.parse(close));
    }
  }
  return closes;
}
