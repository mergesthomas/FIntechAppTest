import 'package:equatable/equatable.dart';

/// ISO-like code plus ledger units (xUSD, EURx). Precision is explicit.
final class Currency extends Equatable {
  const Currency({
    required this.code,
    required this.scale,
  });

  final String code;
  final int scale;

  static const eur = Currency(code: 'EUR', scale: 2);
  static const usd = Currency(code: 'USD', scale: 2);
  static const gbp = Currency(code: 'GBP', scale: 2);
  static const usdx = Currency(code: 'USDx', scale: 2);
  static const eurx = Currency(code: 'EURx', scale: 2);
  static const gbpx = Currency(code: 'GBPx', scale: 2);
  static const xusd = Currency(code: 'xUSD', scale: 2);

  static const doge = Currency(code: 'DOGE', scale: 8);
  static const btc = Currency(code: 'BTC', scale: 8);
  static const eth = Currency(code: 'ETH', scale: 8);
  static const usdc = Currency(code: 'USDC', scale: 6);
  static const usdt = Currency(code: 'USDT', scale: 6);
  static const nexo = Currency(code: 'NEXO', scale: 8);

  static Currency parse(String code) {
    return byCode[code] ?? Currency(code: code, scale: 8);
  }

  static const Map<String, Currency> byCode = {
    'EUR': eur,
    'USD': usd,
    'GBP': gbp,
    'USDx': usdx,
    'EURx': eurx,
    'GBPx': gbpx,
    'xUSD': xusd,
    'DOGE': doge,
    'BTC': btc,
    'ETH': eth,
    'USDC': usdc,
    'USDT': usdt,
    'NEXO': nexo,
  };

  @override
  List<Object?> get props => [code, scale];
}
