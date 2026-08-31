import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/market_tick.dart';
import '../../domain/usecases/market_usecases.dart';

sealed class MarketState extends Equatable {
  const MarketState();

  @override
  List<Object?> get props => [];
}

final class MarketLoading extends MarketState {
  const MarketLoading();
}

final class MarketEmpty extends MarketState {
  const MarketEmpty();
}

final class MarketFailure extends MarketState {
  const MarketFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class MarketSuccess extends MarketState {
  const MarketSuccess({
    required this.asset,
    required this.candles,
    this.showVolume = true,
  });

  final MarketAsset asset;
  final CandleSeries candles;
  final bool showVolume;

  MarketSuccess copyWith({
    MarketAsset? asset,
    CandleSeries? candles,
    bool? showVolume,
  }) {
    return MarketSuccess(
      asset: asset ?? this.asset,
      candles: candles ?? this.candles,
      showVolume: showVolume ?? this.showVolume,
    );
  }

  @override
  List<Object?> get props => [asset, candles, showVolume];
}

class MarketCubit extends Cubit<MarketState> {
  MarketCubit({
    required GetMarketAsset getAsset,
    required GetCandleChart getCandles,
    required WatchMarketTicks watchTicks,
    required this.code,
  })  : _getAsset = getAsset,
        _getCandles = getCandles,
        _watchTicks = watchTicks,
        super(const MarketLoading());

  final GetMarketAsset _getAsset;
  final GetCandleChart _getCandles;
  final WatchMarketTicks _watchTicks;
  final String code;
  StreamSubscription<Either<Failure, MarketTick>>? _ticks;

  Currency? get _currency => Currency.tryParse(code);

  Future<void> load({
    CandleInterval interval = CandleInterval.m15,
  }) async {
    final currency = _currency;
    if (currency == null) {
      emit(const MarketFailure(ValidationFailure('unknown_asset')));
      return;
    }
    emit(const MarketLoading());
    final asset = await _getAsset((
      currency: currency,
      period: ChartPeriod.oneDay,
    ));
    if (isClosed) {
      return;
    }
    final candles = await _getCandles((
      currency: currency,
      interval: interval,
    ));
    if (isClosed) {
      return;
    }
    asset.fold(
      (failure) => emit(MarketFailure(failure)),
      (loaded) {
        candles.fold(
          (failure) => emit(MarketFailure(failure)),
          (series) {
            emit(MarketSuccess(asset: loaded, candles: series));
            _bindTicks(currency);
          },
        );
      },
    );
  }

  Future<void> selectInterval(CandleInterval interval) async {
    final currency = _currency;
    final current = state;
    if (currency == null || current is! MarketSuccess) {
      await load(interval: interval);
      return;
    }
    final result = await _getCandles((
      currency: currency,
      interval: interval,
    ));
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(MarketFailure(failure)),
      (series) => emit(current.copyWith(candles: series)),
    );
  }

  void toggleVolume() {
    final current = state;
    if (current is! MarketSuccess) {
      return;
    }
    emit(current.copyWith(showVolume: !current.showVolume));
  }

  void _bindTicks(Currency currency) {
    _ticks?.cancel();
    _ticks = _watchTicks(currency).listen((event) {
      final current = state;
      if (current is! MarketSuccess || isClosed) {
        return;
      }
      event.fold((_) {}, (tick) {
        emit(
          current.copyWith(
            asset: current.asset.copyWith(
              price: tick.price,
              change24h: tick.change24h,
              freshness: tick.freshness,
            ),
            candles: current.candles.applyTick(
              price: tick.last,
              at: tick.at,
            ),
          ),
        );
      });
    });
  }

  @override
  Future<void> close() {
    _ticks?.cancel();
    return super.close();
  }
}
