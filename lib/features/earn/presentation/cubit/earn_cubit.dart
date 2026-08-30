import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/earn.dart';
import '../../domain/usecases/earn_usecases.dart';

sealed class EarnState extends Equatable {
  const EarnState();

  @override
  List<Object?> get props => [];
}

final class EarnLoading extends EarnState {
  const EarnLoading();
}

final class EarnEmpty extends EarnState {
  const EarnEmpty();
}

final class EarnFailure extends EarnState {
  const EarnFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class EarnSuccess extends EarnState {
  const EarnSuccess({
    required this.overview,
    required this.products,
    required this.preference,
    this.job,
  });

  final SavingsHubOverview overview;
  final List<EarnProductTeaser> products;
  final EarnPreference preference;
  final SettlementStatus? job;

  @override
  List<Object?> get props => [overview, products, preference, job];
}

class EarnCubit extends Cubit<EarnState> {
  EarnCubit({
    required GetSavingsHubOverview getOverview,
    required GetEarnProducts getProducts,
    required GetEarnInNexoPreference getPreference,
    required SetEarnInNexo setEarnInNexo,
    required StopEarning stopEarning,
  })  : _getOverview = getOverview,
        _getProducts = getProducts,
        _getPreference = getPreference,
        _setEarnInNexo = setEarnInNexo,
        _stopEarning = stopEarning,
        super(const EarnLoading());

  final GetSavingsHubOverview _getOverview;
  final GetEarnProducts _getProducts;
  final GetEarnInNexoPreference _getPreference;
  final SetEarnInNexo _setEarnInNexo;
  final StopEarning _stopEarning;

  Future<void> load() async {
    emit(const EarnLoading());
    final overview = await _getOverview(const NoParams());
    await overview.fold((failure) async => emit(EarnFailure(failure)), (o) async {
      final products = await _getProducts(const NoParams());
      final preference = await _getPreference(const NoParams());
      if (products.isLeft() || preference.isLeft()) {
        emit(const EarnFailure(ServerFailure('earn_partial_failure')));
        return;
      }
      final list = products.getRight().toNullable()!;
      if (list.isEmpty) {
        emit(const EarnEmpty());
        return;
      }
      emit(
        EarnSuccess(
          overview: o,
          products: list,
          preference: preference.getRight().toNullable()!,
        ),
      );
    });
  }

  Future<void> toggleEarnInNexo({
    required bool enabled,
    required String requestId,
    required bool stepUp,
  }) async {
    final result = await _setEarnInNexo((
      requestId: requestId,
      enabled: enabled,
      stepUp: stepUp,
    ));
    result.fold((failure) => emit(EarnFailure(failure)), (_) => load());
  }

  Future<void> stop({required String requestId, required bool stepUp}) async {
    final result = await _stopEarning((requestId: requestId, stepUp: stepUp));
    result.fold((failure) => emit(EarnFailure(failure)), (_) => load());
  }
}
