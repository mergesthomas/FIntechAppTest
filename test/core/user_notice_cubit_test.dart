import 'package:fintech_app_test/core/error/failure.dart';
import 'package:fintech_app_test/core/notice/failure_message.dart';
import 'package:fintech_app_test/core/notice/user_notice.dart';
import 'package:fintech_app_test/core/notice/user_notice_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('show queues a notice with an increasing sequence', () {
    final cubit = UserNoticeCubit();
    cubit.success('Added SOL to your watchlist.');
    final first = cubit.state as UserNoticeQueued;
    expect(first.notice.kind, UserNoticeKind.success);
    expect(first.notice.message, 'Added SOL to your watchlist.');
    cubit.fromFailure(const SessionFailure());
    final second = cubit.state as UserNoticeQueued;
    expect(second.sequence, greaterThan(first.sequence));
    expect(second.notice.message, FailureMessage.map(const SessionFailure()));
    cubit.close();
  });
}
