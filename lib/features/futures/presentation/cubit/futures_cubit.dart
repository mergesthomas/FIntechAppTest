import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/futures.dart';
import '../../domain/usecases/futures_usecases.dart';

enum FuturesSurface { ticket, preview, position, result }

sealed class FuturesState extends Equatable {
  const FuturesState();

  @override
  List<Object?> get props => [];
}

final class FuturesLoading extends FuturesState {
  const FuturesLoading();
}

final class FuturesEmpty extends FuturesState {
  const FuturesEmpty();
}

final class FuturesFailure extends FuturesState {
  const FuturesFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class FuturesReady extends FuturesState {
  const FuturesReady({
    required this.surface,
    required this.instrument,
    required this.account,
    required this.positions,
    required this.trades,
    this.quote,
    this.details,
    this.result,
  });

  final FuturesSurface surface;
  final FuturesInstrument instrument;
  final FuturesAccount account;
  final List<FuturesPosition> positions;
  final List<FuturesTrade> trades;
  final FuturesQuote? quote;
  final FuturesPositionDetails? details;
  final Object? result;

  FuturesReady copyWith({
    FuturesSurface? surface,
    FuturesInstrument? instrument,
    FuturesAccount? account,
    List<FuturesPosition>? positions,
    List<FuturesTrade>? trades,
    FuturesQuote? quote,
    FuturesPositionDetails? details,
    Object? result,
  }) {
    return FuturesReady(
      surface: surface ?? this.surface,
      instrument: instrument ?? this.instrument,
      account: account ?? this.account,
      positions: positions ?? this.positions,
      trades: trades ?? this.trades,
      quote: quote ?? this.quote,
      details: details ?? this.details,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
        surface,
        instrument,
        account,
        positions,
        trades,
        quote,
        details,
        result,
      ];
}

class FuturesCubit extends Cubit<FuturesState> {
  FuturesCubit({
    required GetFuturesInstrument getInstrument,
    required GetFuturesAccount getAccount,
    required GetOpenPositions getPositions,
    required GetLastTrades getTrades,
    required GetPositionDetails getDetails,
    required PreviewFuturesPosition previewPosition,
    required SubmitFuturesOrder submit,
    required SetTakeProfitStopLoss setTpsl,
    required ClosePosition close,
  })  : _getInstrument = getInstrument,
        _getAccount = getAccount,
        _getPositions = getPositions,
        _getTrades = getTrades,
        _getDetails = getDetails,
        _previewPosition = previewPosition,
        _submit = submit,
        _setTpsl = setTpsl,
        _close = close,
        super(const FuturesLoading());

  final GetFuturesInstrument _getInstrument;
  final GetFuturesAccount _getAccount;
  final GetOpenPositions _getPositions;
  final GetLastTrades _getTrades;
  final GetPositionDetails _getDetails;
  final PreviewFuturesPosition _previewPosition;
  final SubmitFuturesOrder _submit;
  final SetTakeProfitStopLoss _setTpsl;
  final ClosePosition _close;

  FuturesReady? get _ready =>
      state is FuturesReady ? state as FuturesReady : null;

  Future<void> load() async {
    emit(const FuturesLoading());
    final instrument = await _getInstrument(const NoParams());
    await instrument.fold((failure) async => emit(FuturesFailure(failure)), (
      i,
    ) async {
      final account = await _getAccount(const NoParams());
      final positions = await _getPositions(const NoParams());
      final trades = await _getTrades(const NoParams());
      if (account.isLeft() || positions.isLeft() || trades.isLeft()) {
        emit(const FuturesFailure(ServerFailure('futures_partial_failure')));
        return;
      }
      emit(
        FuturesReady(
          surface: FuturesSurface.ticket,
          instrument: i,
          account: account.getRight().toNullable()!,
          positions: positions.getRight().toNullable()!,
          trades: trades.getRight().toNullable()!,
        ),
      );
    });
  }

  Future<void> preview({FuturesSide side = FuturesSide.long}) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final quote = await _previewPosition((
      side: side,
      size: Money.parse('0.01', Currency.btc),
    ));
    quote.fold(
      (failure) => emit(FuturesFailure(failure)),
      (q) => emit(current.copyWith(surface: FuturesSurface.preview, quote: q)),
    );
  }

  Future<void> confirm({required String requestId, required bool stepUp}) async {
    final current = _ready;
    final quote = current?.quote;
    if (current == null || quote == null) {
      return;
    }
    final result = await _submit((
      requestId: requestId,
      quoteId: quote.quoteId,
      stepUp: stepUp,
    ));
    result.fold(
      (failure) => emit(
        current.copyWith(surface: FuturesSurface.result, result: failure),
      ),
      (submit) => emit(
        current.copyWith(surface: FuturesSurface.result, result: submit),
      ),
    );
  }

  Future<void> openPosition(String id) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final details = await _getDetails(id);
    details.fold(
      (failure) => emit(FuturesFailure(failure)),
      (value) => emit(
        current.copyWith(surface: FuturesSurface.position, details: value),
      ),
    );
  }

  Future<void> setTpsl({
    required String positionId,
    required String requestId,
    required bool stepUp,
  }) async {
    final current = _ready;
    final result = await _setTpsl((
      requestId: requestId,
      positionId: positionId,
      stepUp: stepUp,
    ));
    result.fold(
      (failure) => emit(
        current?.copyWith(surface: FuturesSurface.result, result: failure) ??
            FuturesFailure(failure),
      ),
      (status) => emit(
        current?.copyWith(surface: FuturesSurface.result, result: status) ??
            const FuturesFailure(ServerFailure()),
      ),
    );
  }

  Future<void> closePosition({
    required String positionId,
    required String requestId,
    required bool stepUp,
  }) async {
    final current = _ready;
    final result = await _close((
      requestId: requestId,
      positionId: positionId,
      stepUp: stepUp,
    ));
    result.fold(
      (failure) => emit(
        current?.copyWith(surface: FuturesSurface.result, result: failure) ??
            FuturesFailure(failure),
      ),
      (status) => emit(
        current?.copyWith(surface: FuturesSurface.result, result: status) ??
            const FuturesFailure(ServerFailure()),
      ),
    );
  }
}
