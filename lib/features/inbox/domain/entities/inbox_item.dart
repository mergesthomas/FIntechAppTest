import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

final class InboxItem extends Equatable {
  const InboxItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dateLabel,
  });

  final String id;
  final String title;
  final Money amount;
  final String dateLabel;

  @override
  List<Object?> get props => [id, title, amount, dateLabel];
}
