import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/inbox_item.dart';

final class InboxLocalDataSource {
  const InboxLocalDataSource();

  List<InboxItem> items() {
    return [
      InboxItem(
        id: '1',
        title: 'Interest Earned',
        amount: Money.parse('2.40', Currency.usd),
        dateLabel: 'Today',
      ),
    ];
  }
}
