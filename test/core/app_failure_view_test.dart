import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/notice/failure_message.dart';
import 'package:fintech_app_test/core/notice/notice_copy.dart';
import 'package:fintech_app_test/core/theme/app_theme.dart';
import 'package:fintech_app_test/core/widgets/app_failure_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows mapped copy and retry, never a Failure type name', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppFailureView(
            failure: const ValidationFailure('unknown_asset'),
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('Failure'), findsNothing);
    expect(
      find.text(FailureMessage.map(const ValidationFailure('unknown_asset'))),
      findsOneWidget,
    );
    await tester.tap(find.text(NoticeCopy.retry));
    expect(retried, isTrue);
  });
}
