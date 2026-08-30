import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/session.dart';
import '../../domain/usecases/session_usecases.dart';

sealed class BiometricState extends Equatable {
  const BiometricState();

  @override
  List<Object?> get props => [];
}

final class BiometricEmpty extends BiometricState {
  const BiometricEmpty();
}

final class BiometricLoading extends BiometricState {
  const BiometricLoading();
}

final class BiometricSuccess extends BiometricState {
  const BiometricSuccess(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}

final class BiometricFailure extends BiometricState {
  const BiometricFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class BiometricCubit extends Cubit<BiometricState> {
  BiometricCubit({
    required EnableBiometric enableBiometric,
    required SkipBiometric skipBiometric,
  })  : _enableBiometric = enableBiometric,
        _skipBiometric = skipBiometric,
        super(const BiometricEmpty());

  final EnableBiometric _enableBiometric;
  final SkipBiometric _skipBiometric;

  Future<void> enable() async {
    emit(const BiometricLoading());
    final result = await _enableBiometric(const NoParams());
    result.fold(
      (failure) => emit(BiometricFailure(failure)),
      (session) => emit(BiometricSuccess(session)),
    );
  }

  Future<void> skip() async {
    emit(const BiometricLoading());
    final result = await _skipBiometric(const NoParams());
    result.fold(
      (failure) => emit(BiometricFailure(failure)),
      (session) => emit(BiometricSuccess(session)),
    );
  }
}
