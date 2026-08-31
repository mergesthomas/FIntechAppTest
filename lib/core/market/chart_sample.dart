import 'package:equatable/equatable.dart';

import '../money/money.dart';

final class ChartSample extends Equatable {
  const ChartSample({required this.value, required this.at});

  final Money value;
  final DateTime at;

  @override
  List<Object?> get props => [value, at];
}
