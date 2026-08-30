import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_auth.dart';
import '../../domain/usecases/sms_usecases.dart';

sealed class PhoneAuthState extends Equatable {
  const PhoneAuthState();

  @override
  List<Object?> get props => [];
}

final class PhoneAuthEmpty extends PhoneAuthState {
  const PhoneAuthEmpty();
}

final class PhoneAuthLoading extends PhoneAuthState {
  const PhoneAuthLoading();
}

final class PhoneAuthSuccess extends PhoneAuthState {
  const PhoneAuthSuccess(this.pending);

  final PendingAuth pending;

  @override
  List<Object?> get props => [pending];
}

final class PhoneAuthFailure extends PhoneAuthState {
  const PhoneAuthFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class PhoneAuthCubit extends Cubit<PhoneAuthState> {
  PhoneAuthCubit({
    required StartLogin startLogin,
    required StartSignUp startSignUp,
  })  : _startLogin = startLogin,
        _startSignUp = startSignUp,
        super(const PhoneAuthEmpty());

  final StartLogin _startLogin;
  final StartSignUp _startSignUp;

  Future<void> submit({required String phone, required AuthIntent intent}) async {
    emit(const PhoneAuthLoading());
    final result = intent == AuthIntent.login
        ? await _startLogin(phone)
        : await _startSignUp(phone);
    result.fold(
      (failure) => emit(PhoneAuthFailure(failure)),
      (pending) => emit(PhoneAuthSuccess(pending)),
    );
  }
}
