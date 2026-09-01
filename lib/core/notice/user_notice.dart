import 'package:equatable/equatable.dart';

import '../error/failure.dart';
import 'failure_message.dart';

enum UserNoticeKind { success, error, warning, info }

final class UserNotice extends Equatable {
  const UserNotice({
    required this.kind,
    required this.message,
  });

  factory UserNotice.success(String message) {
    return UserNotice(kind: UserNoticeKind.success, message: message);
  }

  factory UserNotice.error(String message) {
    return UserNotice(kind: UserNoticeKind.error, message: message);
  }

  factory UserNotice.warning(String message) {
    return UserNotice(kind: UserNoticeKind.warning, message: message);
  }

  factory UserNotice.info(String message) {
    return UserNotice(kind: UserNoticeKind.info, message: message);
  }

  factory UserNotice.fromFailure(Failure failure) {
    return UserNotice.error(FailureMessage.map(failure));
  }

  final UserNoticeKind kind;
  final String message;

  @override
  List<Object?> get props => [kind, message];
}
