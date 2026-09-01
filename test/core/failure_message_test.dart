import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/notice/failure_message.dart';
import 'package:fintech_app_test/core/notice/notice_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('never prints a Failure type name', () {
    const failures = <Failure>[
      SessionFailure(),
      EligibilityFailure(),
      StaleQuoteFailure(),
      StepUpFailure(),
      ValidationFailure('unknown_asset'),
      AuthFailure('invalid_sms_code'),
      ServerFailure('dashboard_partial_failure'),
      ValidationFailure('not_a_real_reason'),
    ];
    for (final failure in failures) {
      final message = FailureMessage.map(failure);
      expect(message, isNot(contains('Failure')));
      expect(message, isNot(contains('unknown_asset')));
      expect(message, isNotEmpty);
    }
  });

  test('maps session and unknown asset to product copy', () {
    expect(FailureMessage.map(const SessionFailure()), NoticeCopy.sessionExpired);
    expect(
      FailureMessage.map(const ValidationFailure('unknown_asset')),
      'This asset isn’t available yet.',
    );
    expect(
      FailureMessage.map(const ValidationFailure('watchlist_already_contains')),
      'That coin is already on your watchlist.',
    );
  });
}
