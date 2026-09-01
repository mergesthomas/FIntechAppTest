import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/card.dart';
import '../../domain/usecases/card_usecases.dart';

sealed class CardUiState extends Equatable {
  const CardUiState();

  @override
  List<Object?> get props => [];
}

final class CardLoading extends CardUiState {
  const CardLoading();
}

final class CardEmpty extends CardUiState {
  const CardEmpty();
}

final class CardFailure extends CardUiState {
  const CardFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class CardSuccess extends CardUiState {
  const CardSuccess(this.snapshot);

  final CardSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

class CardCubit extends Cubit<CardUiState> {
  CardCubit({
    required GetCardStatus getStatus,
    required RestoreCardBalance restore,
    required UnfreezeCard unfreeze,
    required FreezeCard freeze,
    required RevealCardPin revealPin,
  })  : _getStatus = getStatus,
        _restore = restore,
        _unfreeze = unfreeze,
        _freeze = freeze,
        _revealPin = revealPin,
        super(const CardLoading());

  final GetCardStatus _getStatus;
  final RestoreCardBalance _restore;
  final UnfreezeCard _unfreeze;
  final FreezeCard _freeze;
  final RevealCardPin _revealPin;

  Future<void> load() async {
    emit(const CardLoading());
    final result = await _getStatus(const NoParams());
    result.fold(
      (failure) => emit(CardFailure(failure)),
      (snapshot) => emit(
        snapshot.status == CardStatus.none
            ? const CardEmpty()
            : CardSuccess(snapshot),
      ),
    );
  }

  Future<Either<Failure, RestoreRail>> restore(RestoreRail rail) {
    return _restore(rail);
  }

  Future<void> unfreeze() async {
    final result = await _unfreeze(const NoParams());
    result.fold((failure) => emit(CardFailure(failure)), (_) => load());
  }

  Future<void> freeze() async {
    final result = await _freeze(const NoParams());
    result.fold((failure) => emit(CardFailure(failure)), (_) => load());
  }

  Future<Either<Failure, String>> revealPin({required bool stepUp}) {
    return _revealPin((stepUp: stepUp));
  }
}
