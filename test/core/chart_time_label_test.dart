import 'package:fintech_app_test/core/clock/chart_time_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('labels a UTC date and optional time without intl', () {
    final at = DateTime.utc(2025, 3, 12, 14, 5);
    expect(chartTimeLabel(at, includeTime: false), 'Mar 12, 2025');
    expect(chartTimeLabel(at, includeTime: true), 'Mar 12, 2025 14:05');
    expect(clockTimeLabel(at), '14:05');
  });
}
