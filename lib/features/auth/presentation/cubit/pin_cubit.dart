import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/pin_draft.dart';
import '../../domain/usecases/pin_usecases.dart';

sealed class PinState extends Equatable {
  const PinState();

  @override
  List<Object?> get props => [];
}

final class PinEmpty extends PinState {
  const PinEmpty();
}

final class PinLoading extends PinState {
  const PinLoading();
}

final class PinCreated extends PinState {
  const PinCreated(this.draft);

  final PinDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class PinConfirmed extends PinState {
  const PinConfirmed();
}

final class PinFailure extends PinState {
  const PinFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class PinCubit extends Cubit<PinState> {
  PinCubit({
    required CreatePin createPin,
    required ConfirmPin confirmPin,
    required ResetPinDraft resetPinDraft,
  })  : _createPin = createPin,
        _confirmPin = confirmPin,
        _resetPinDraft = resetPinDraft,
        super(const PinEmpty());

  final CreatePin _createPin;
  final ConfirmPin _confirmPin;
  final ResetPinDraft _resetPinDraft;

  Future<void> create(String pin) async {
    emit(const PinLoading());
    final result = await _createPin(pin);
    result.fold(
      (failure) => emit(PinFailure(failure)),
      (draft) => emit(PinCreated(draft)),
    );
  }

  Future<void> confirm(String pin) async {
    final current = state;
    if (current is! PinCreated) {
      emit(const PinFailure(AuthFailure('pin_draft_missing')));
      return;
    }
    emit(const PinLoading());
    final result = await _confirmPin(
      ConfirmPinParams(draft: current.draft, pin: pin),
    );
    result.fold(
      (failure) => emit(PinFailure(failure)),
      (_) => emit(const PinConfirmed()),
    );
  }

  Future<void> reset() async {
    await _resetPinDraft(const NoParams());
    emit(const PinEmpty());
  }
}
