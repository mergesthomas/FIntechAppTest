import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/failure.dart';
import 'user_notice.dart';

sealed class UserNoticeState extends Equatable {
  const UserNoticeState();

  @override
  List<Object?> get props => [];
}

final class UserNoticeIdle extends UserNoticeState {
  const UserNoticeIdle();
}

final class UserNoticeQueued extends UserNoticeState {
  const UserNoticeQueued({required this.notice, required this.sequence});

  final UserNotice notice;
  final int sequence;

  @override
  List<Object?> get props => [notice, sequence];
}

/// Transient success / error / info toasts. Feature cubits do not depend on
/// this — pages report notices after Use Case results.
class UserNoticeCubit extends Cubit<UserNoticeState> {
  UserNoticeCubit() : super(const UserNoticeIdle());

  var _sequence = 0;

  void show(UserNotice notice) {
    _sequence += 1;
    emit(UserNoticeQueued(notice: notice, sequence: _sequence));
  }

  void success(String message) => show(UserNotice.success(message));

  void error(String message) => show(UserNotice.error(message));

  void warning(String message) => show(UserNotice.warning(message));

  void info(String message) => show(UserNotice.info(message));

  void fromFailure(Failure failure) => show(UserNotice.fromFailure(failure));
}

extension UserNoticeContext on BuildContext {
  UserNoticeCubit get userNotices => read<UserNoticeCubit>();

  void showUserNotice(UserNotice notice) => userNotices.show(notice);

  void showFailureNotice(Failure failure) => userNotices.fromFailure(failure);
}
