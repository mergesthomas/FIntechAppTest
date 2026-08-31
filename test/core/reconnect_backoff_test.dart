import 'package:fintech_app_test/core/market/reconnect_backoff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('doubles until max and resets after a payload', () {
    final backoff = ReconnectBackoff(
      initial: const Duration(seconds: 1),
      max: const Duration(seconds: 8),
    );
    expect(backoff.next(), const Duration(seconds: 1));
    expect(backoff.next(), const Duration(seconds: 2));
    expect(backoff.next(), const Duration(seconds: 4));
    expect(backoff.next(), const Duration(seconds: 8));
    expect(backoff.next(), const Duration(seconds: 8));
    backoff.reset();
    expect(backoff.next(), const Duration(seconds: 1));
  });
}
