import 'package:fintech_app_test/features/inbox/data/datasources/inbox_local_datasource.dart';
import 'package:fintech_app_test/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixture inbox uses Money amounts', () async {
    final repo = InboxRepositoryImpl(const InboxLocalDataSource());
    final items = await repo.getItems();
    expect(items.getRight().toNullable()?.first.amount.currency.code, 'USD');
  });
}
