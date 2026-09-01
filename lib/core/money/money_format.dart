import 'package:decimal/decimal.dart';

import 'currency.dart';
import 'money.dart';

/// How a [Money] value is shown. Domain precision is unchanged.
enum MoneyFormat {
  /// USD marks, last, OHLC, holdings value.
  price,

  /// Wallet / ticket size (BTC, DOGE, USDC, …).
  quantity,

  /// Conversion (1 USDC = n DOGE).
  rate,
}

/// Quantity with grouping, capped scale, trimmed zeros, optional code.
String formatQuantity(Money money, {bool withCode = true}) {
  return _format(money, kind: MoneyFormat.quantity, withCode: withCode);
}

/// Formats [Money] without converting to [double].
String formatMoney(
  Money money, {
  bool withCode = false,
  MoneyFormat kind = MoneyFormat.price,
}) {
  return _format(money, kind: kind, withCode: withCode);
}

/// Conversion rate. Caps fraction digits; does not pad trailing zeros.
String formatRate(Money perUnit, {bool withCode = true}) {
  return _format(perUnit, kind: MoneyFormat.rate, withCode: withCode);
}

/// Signed percent from a ratio (`-0.0151` → `-1.51%`). No [double].
String formatPercent(Decimal ratio, {int scale = 2, bool signed = true}) {
  final pct = _roundTo(ratio * Decimal.fromInt(100), scale);
  final text = _decimalText(pct, scale: scale, pad: true);
  if (pct == Decimal.zero) {
    return '${_decimalText(Decimal.zero, scale: scale, pad: true)}%';
  }
  if (signed && pct > Decimal.zero) {
    return '+$text%';
  }
  return '$text%';
}

/// OHLC / volume display. Fixed fraction so the row width stays stable.
String formatMarketDecimal(Decimal amount, {int scale = 2}) {
  final rounded = _roundTo(amount, scale);
  final raw = _decimalText(rounded, scale: scale, pad: true);
  final sign = raw.startsWith('-') ? '-' : '';
  final unsigned = sign.isEmpty ? raw : raw.substring(1);
  final parts = unsigned.split('.');
  final whole = _commas(parts.first);
  final fraction = parts.length > 1 ? '.${parts[1]}' : '';
  return '$sign$whole$fraction';
}

String _format(
  Money money, {
  required MoneyFormat kind,
  required bool withCode,
}) {
  final abs = money.amount.abs();
  final scale = _fractionScale(
    currency: money.currency,
    amount: abs,
    kind: kind,
  );
  final pad =
      kind == MoneyFormat.price &&
      _isFiat(money.currency) &&
      abs >= Decimal.one;
  final rounded = _roundTo(money.amount, scale);
  final raw = _decimalText(rounded, scale: scale, pad: pad);
  final parts = raw.split('.');
  final whole = _commas(
    parts.first.startsWith('-') ? parts.first.substring(1) : parts.first,
  );
  final sign = raw.startsWith('-') ? '-' : '';
  final fraction = parts.length > 1 ? '.${parts[1]}' : '';
  final symbol =
      kind != MoneyFormat.quantity && money.currency.code == 'USD' ? '\$' : '';
  final suffix =
      withCode && symbol.isEmpty ? ' ${money.currency.code}' : '';
  return '$sign$symbol$whole$fraction$suffix';
}

int _fractionScale({
  required Currency currency,
  required Decimal amount,
  required MoneyFormat kind,
}) {
  if (kind == MoneyFormat.rate) {
    return _rateScale(currency, amount);
  }
  if (kind == MoneyFormat.quantity) {
    return _quantityScale(currency, amount);
  }
  return _priceScale(currency, amount);
}

int _priceScale(Currency currency, Decimal amount) {
  if (_isFiat(currency) || currency.code == 'USDT' || currency.code == 'USDC') {
    if (amount == Decimal.zero) {
      return 2;
    }
    if (amount >= Decimal.one) {
      return 2;
    }
    if (amount >= Decimal.parse('0.01')) {
      return 4;
    }
    return _dustScale(amount, minScale: 2);
  }
  return _quantityScale(currency, amount);
}

int _quantityScale(Currency currency, Decimal amount) {
  if (_keepDust(currency)) {
    if (amount == Decimal.zero) {
      return currency.scale;
    }
    return _trimmedScale(amount, maxScale: currency.scale);
  }
  final max = switch (currency.code) {
    'USDC' || 'USDT' => 2,
    'DOGE' => 4,
    'XRP' => 4,
    _ => currency.scale,
  };
  if (amount == Decimal.zero) {
    return 0;
  }
  return _trimmedScale(amount, maxScale: max);
}

int _rateScale(Currency currency, Decimal amount) {
  if (_keepDust(currency)) {
    return _dustScale(amount, minScale: 2);
  }
  if (amount >= Decimal.one) {
    return _trimmedScale(amount, maxScale: 6);
  }
  if (currency.code == 'DOGE' || amount >= Decimal.parse('0.01')) {
    return _trimmedScale(amount, maxScale: 6);
  }
  return _dustScale(amount, minScale: 4);
}

/// Fiat scale would hide dust quotes (BONK/PEPE) as `$0.00`.
int _dustScale(Decimal amount, {required int minScale}) {
  if (amount == Decimal.zero) {
    return minScale;
  }
  final fraction = amount.toString().split('.').length > 1
      ? amount.toString().split('.')[1]
      : '';
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

int _trimmedScale(Decimal amount, {required int maxScale}) {
  if (maxScale <= 0) {
    return 0;
  }
  final rounded = _roundTo(amount, maxScale);
  final fraction = rounded.toString().split('.').length > 1
      ? rounded.toString().split('.')[1]
      : '';
  var end = fraction.length;
  while (end > 0 && fraction[end - 1] == '0') {
    end--;
  }
  if (end > maxScale) {
    return maxScale;
  }
  return end;
}

bool _keepDust(Currency currency) {
  return currency.code == 'PEPE' || currency.code == 'BONK';
}

bool _isFiat(Currency currency) {
  return switch (currency.code) {
    'USD' || 'USDx' || 'EURx' || 'GBPx' || 'xUSD' => true,
    _ => false,
  };
}

Decimal _roundTo(Decimal amount, int scale) {
  if (scale <= 0) {
    return amount.round();
  }
  var factor = Decimal.one;
  for (var i = 0; i < scale; i++) {
    factor *= Decimal.fromInt(10);
  }
  return ((amount * factor).round() / factor).toDecimal(
    scaleOnInfinitePrecision: scale,
  );
}

String _decimalText(Decimal amount, {required int scale, required bool pad}) {
  final raw = amount.toString();
  final sign = raw.startsWith('-') ? '-' : '';
  final unsigned = sign.isEmpty ? raw : raw.substring(1);
  final parts = unsigned.split('.');
  final whole = parts.first.isEmpty ? '0' : parts.first;
  var fraction = parts.length > 1 ? parts[1] : '';
  if (pad) {
    fraction = fraction.padRight(scale, '0');
    if (scale == 0) {
      return '$sign$whole';
    }
    return '$sign$whole.${fraction.substring(0, scale)}';
  }
  if (scale == 0 || fraction.isEmpty) {
    return '$sign$whole';
  }
  if (fraction.length > scale) {
    fraction = fraction.substring(0, scale);
  }
  while (fraction.endsWith('0')) {
    fraction = fraction.substring(0, fraction.length - 1);
  }
  if (fraction.isEmpty) {
    return '$sign$whole';
  }
  return '$sign$whole.$fraction';
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
