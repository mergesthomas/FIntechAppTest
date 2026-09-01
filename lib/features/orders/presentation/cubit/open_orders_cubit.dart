import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/settlement/request_id.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/orders_usecases.dart';

sealed class OpenOrdersState extends Equatable {
  const OpenOrdersState();

  @override
  List<Object?> get props => [];
}

final class OpenOrdersLoading extends OpenOrdersState {
  const OpenOrdersLoading();
}

final class OpenOrdersEmpty extends OpenOrdersState {
  const OpenOrdersEmpty();
}

final class OpenOrdersFailure extends OpenOrdersState {
  const OpenOrdersFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class OpenOrdersReady extends OpenOrdersState {
  const OpenOrdersReady({
    required this.orders,
    this.submittingId,
    this.failure,
  });

  final List<TradeOrder> orders;
  final String? submittingId;
  final Failure? failure;

  OpenOrdersReady copyWith({
    List<TradeOrder>? orders,
    String? submittingId,
    Failure? failure,
    bool clearSubmitting = false,
    bool clearFailure = false,
  }) {
    return OpenOrdersReady(
      orders: orders ?? this.orders,
      submittingId: clearSubmitting ? null : submittingId ?? this.submittingId,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [orders, submittingId, failure];
}

class OpenOrdersCubit extends Cubit<OpenOrdersState> {
  OpenOrdersCubit({
    required GetOpenOrdersForAsset getOpen,
    required CancelOrder cancel,
    required RequestIdFactory requestIds,
    required this.code,
  })  : _getOpen = getOpen,
        _cancel = cancel,
        _requestIds = requestIds,
        super(const OpenOrdersLoading());

  final GetOpenOrdersForAsset _getOpen;
  final CancelOrder _cancel;
  final RequestIdFactory _requestIds;
  final String code;
  final Map<String, String> _cancelIds = {};

  Currency? get _asset => Currency.fromCode(code);

  Future<void> load() async {
    final asset = _asset;
    if (asset == null) {
      emit(const OpenOrdersFailure(ValidationFailure('unknown_asset')));
      return;
    }
    emit(const OpenOrdersLoading());
    final result = await _getOpen(asset);
    result.fold(
      (failure) => emit(OpenOrdersFailure(failure)),
      (orders) => emit(
        orders.isEmpty
            ? const OpenOrdersEmpty()
            : OpenOrdersReady(orders: orders),
      ),
    );
  }

  Future<SettlementStatus?> cancel({
    required String orderId,
    required bool stepUp,
  }) async {
    final current = state;
    if (current is! OpenOrdersReady || current.submittingId != null) {
      return null;
    }
    emit(current.copyWith(submittingId: orderId, clearFailure: true));
    final requestId = _cancelIds.putIfAbsent(
      orderId,
      () => _requestIds.next('cancel'),
    );
    final result = await _cancel((
      requestId: requestId,
      orderId: orderId,
      stepUp: stepUp,
    ));
    if (isClosed) {
      return null;
    }
    return result.fold(
      (failure) {
        final latest = state;
        if (latest is OpenOrdersReady) {
          emit(
            latest.copyWith(failure: failure, clearSubmitting: true),
          );
        }
        return null;
      },
      (status) {
        _cancelIds.remove(orderId);
        load();
        return status;
      },
    );
  }

  void clearFailure() {
    final current = state;
    if (current is! OpenOrdersReady || current.failure == null) {
      return;
    }
    emit(current.copyWith(clearFailure: true));
  }
}
