import 'package:fintech_app_test/core/market/quote_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live has no printed status label', () {
    expect(QuoteFreshness.live.statusLabel, isNull);
    expect(QuoteFreshness.live.labeled('Bitcoin'), 'Bitcoin');
  });

  test('stale and disconnected stay visible', () {
    expect(QuoteFreshness.stale.labeled('Bitcoin'), 'Bitcoin · stale');
    expect(
      QuoteFreshness.disconnected.labeled('Bitcoin'),
      'Bitcoin · disconnected',
    );
  });
}
