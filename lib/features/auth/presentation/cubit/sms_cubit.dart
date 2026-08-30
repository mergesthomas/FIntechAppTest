import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/usecases/sms_usecases.dart';

sealed class SmsState extends Equatable {
  const SmsState();

  @override
  List<Object?> get props => [];
}

final class SmsEmpty extends SmsState {
  const SmsEmpty();
}

final class SmsLoading extends SmsState {
  const SmsLoading();
}

final class SmsCodeVerified extends SmsState {
  const SmsCodeVerified();
}

final class SmsResent extends SmsState {
  const SmsResent();
}

final class SmsFailure extends SmsState {
  const SmsFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class SmsCubit extends Cubit<SmsState> {
  SmsCubit({
    required VerifySmsCode verifySmsCode,
    required ResendSms resendSms,
  })  : _verifySmsCode = verifySmsCode,
        _resendSms = resendSms,
        super(const SmsEmpty());

  final VerifySmsCode _verifySmsCode;
  final ResendSms _resendSms;

  Future<void> verify(String code) async {
    emit(const SmsLoading());
    final result = await _verifySmsCode(code);
    result.fold(
      (failure) => emit(SmsFailure(failure)),
      (_) => emit(const SmsCodeVerified()),
    );
  }

  Future<void> resend() async {
    emit(const SmsLoading());
    final result = await _resendSms(const NoParams());
    result.fold(
      (failure) => emit(SmsFailure(failure)),
      (_) => emit(const SmsResent()),
    );
  }
}
