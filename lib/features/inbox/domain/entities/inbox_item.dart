import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

enum InboxItemKind { buy, swap, canceled }

final class InboxItem extends Equatable {
  const InboxItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dateLabel,
    required this.kind,
    required this.occurredAt,
    this.unitPrice,
    this.requestId,
  });

  final String id;
  final String title;
  final Money amount;
  final String dateLabel;
  final InboxItemKind kind;
  final DateTime occurredAt;
  final Money? unitPrice;
  final String? requestId;

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        dateLabel,
        kind,
        occurredAt,
        unitPrice,
        requestId,
      ];
}
