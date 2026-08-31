import 'package:fintech_app_test/features/inbox/data/inbox_date_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 31, 15);

  test('buckets today, yesterday, and older calendar days', () {
    expect(inboxDateLabel(DateTime.utc(2026, 8, 31, 1), now), 'Today');
    expect(inboxDateLabel(DateTime.utc(2026, 8, 30, 23), now), 'Yesterday');
    expect(inboxDateLabel(DateTime.utc(2026, 6, 15), now), 'Jun 15, 2026');
  });
}
