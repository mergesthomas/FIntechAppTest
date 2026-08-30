import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';

final class SavingsHubOverview extends Equatable {
  const SavingsHubOverview({required this.interestEarned});

  final Money interestEarned;

  @override
  List<Object?> get props => [interestEarned];
}

final class EarnProductTeaser extends Equatable {
  const EarnProductTeaser({
    required this.id,
    required this.label,
    required this.teaser,
  });

  final String id;
  final String label;
  final String teaser;

  @override
  List<Object?> get props => [id, label, teaser];
}

final class EarnPreference extends Equatable {
  const EarnPreference({required this.earnInNexo});

  final bool earnInNexo;

  @override
  List<Object?> get props => [earnInNexo];
}

final class EarnJob extends Equatable {
  const EarnJob({required this.requestId, required this.settlement});

  final String requestId;
  final SettlementStatus settlement;

  @override
  List<Object?> get props => [requestId, settlement];
}
