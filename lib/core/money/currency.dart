import 'package:equatable/equatable.dart';

final class Currency extends Equatable {
  const Currency({required this.code, required this.scale});

  final String code;
  final int scale;

  static const usd = Currency(code: 'USD', scale: 2);
  static const eurx = Currency(code: 'EURx', scale: 2);
  static const btc = Currency(code: 'BTC', scale: 8);
  static const doge = Currency(code: 'DOGE', scale: 8);
  static const pepe = Currency(code: 'PEPE', scale: 8);
  static const bonk = Currency(code: 'BONK', scale: 8);
  static const nexo = Currency(code: 'NEXO', scale: 8);

  @override
  List<Object?> get props => [code, scale];
}
