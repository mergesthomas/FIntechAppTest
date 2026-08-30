import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/session.dart';
import '../../domain/usecases/session_usecases.dart';

sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SessionEmpty extends SessionState {
  const SessionEmpty();
}

final class SessionSuccess extends SessionState {
  const SessionSuccess(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}

final class SessionFailureState extends SessionState {
  const SessionFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class SessionCubit extends Cubit<SessionState> {
  SessionCubit({
    required RestoreSession restoreSession,
    required LockSession lockSession,
  })  : _restoreSession = restoreSession,
        _lockSession = lockSession,
        super(const SessionLoading());

  final RestoreSession _restoreSession;
  final LockSession _lockSession;

  Future<void> restore() async {
    emit(const SessionLoading());
    final result = await _restoreSession(const NoParams());
    result.fold(
      (failure) {
        if (failure is SessionFailure) {
          emit(const SessionEmpty());
        } else {
          emit(SessionFailureState(failure));
        }
      },
      (session) => emit(SessionSuccess(session)),
    );
  }

  void signedIn(Session session) => emit(SessionSuccess(session));

  Future<void> lock() async {
    emit(const SessionLoading());
    await _lockSession(const NoParams());
    emit(const SessionEmpty());
  }
}
