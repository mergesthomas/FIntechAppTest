import 'package:decimal/decimal.dart';

import 'money.dart';

/// Quantity with grouping, natural scale, and optional currency code.
String formatQuantity(Money money, {bool withCode = true}) {
  final raw = money.amount.toString();
  final parts = raw.split('.');
  final whole = _commas(
    parts.first.startsWith('-') ? parts.first.substring(1) : parts.first,
  );
  final sign = raw.startsWith('-') ? '-' : '';
  final fraction = parts.length > 1 ? '.${parts[1]}' : '';
  final suffix = withCode ? ' ${money.currency.code}' : '';
  return '$sign$whole$fraction$suffix';
}

/// Formats [Money] without converting to [double].
String formatMoney(Money money, {bool withCode = false}) {
  final raw = money.amount.toString();
  final parts = raw.split('.');
  final whole = _commas(
    parts.first.startsWith('-') ? parts.first.substring(1) : parts.first,
  );
  final sign = money.amount.toString().startsWith('-') ? '-' : '';
  final scale = _fractionScale(
    amount: money.amount,
    minScale: money.currency.scale,
    fraction: parts.length > 1 ? parts[1] : '',
  );
  final fraction =
      scale == 0
          ? ''
          : '.${(parts.length > 1 ? parts[1] : '').padRight(scale, '0').substring(0, scale)}';
  final symbol = money.currency.code == 'USD' ? '\$' : '';
  final suffix = withCode && symbol.isEmpty ? ' ${money.currency.code}' : '';
  return '$sign$symbol$whole$fraction$suffix';
}

/// Fiat scale would hide dust quotes (BONK/PEPE) as `$0.00`.
int _fractionScale({
  required Decimal amount,
  required int minScale,
  required String fraction,
}) {
  if (minScale <= 0) {
    return 0;
  }
  if (amount == Decimal.zero) {
    return minScale;
  }
  final shown = fraction.padRight(minScale, '0').substring(0, minScale);
  if (shown.contains(RegExp(r'[1-9]'))) {
    return minScale;
  }
  final significant = fraction.indexOf(RegExp(r'[1-9]'));
  if (significant < 0) {
    return minScale;
  }
  final needed = significant + 2;
  const maxScale = 10;
  if (needed < minScale) {
    return minScale;
  }
  if (needed > maxScale) {
    return maxScale;
  }
  return needed;
}

String _commas(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buf.write(',');
    }
    buf.write(digits[i]);
  }
  return buf.toString();
}
