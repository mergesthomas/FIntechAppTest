import 'money.dart';

/// Formats [Money] without converting to [double].
String formatMoney(Money money, {bool withCode = false}) {
  final raw = money.amount.toString();
  final parts = raw.split('.');
  final whole = _commas(parts.first.startsWith('-') ? parts.first.substring(1) : parts.first);
  final sign = money.amount.toString().startsWith('-') ? '-' : '';
  final fraction = parts.length > 1 ? '.${parts[1].padRight(money.currency.scale, '0').substring(0, money.currency.scale)}' : '';
  final symbol = money.currency.code == 'USD' ? '\$' : '';
  final suffix = withCode && symbol.isEmpty ? ' ${money.currency.code}' : '';
  return '$sign$symbol$whole$fraction$suffix';
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
