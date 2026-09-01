import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/candle_interval.dart';
import '../../../../core/market/candle_series.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/market/quote_freshness.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/market_asset.dart';
import '../../domain/entities/market_tick.dart';
import '../../domain/entities/order_book.dart';
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
    this.orderBook,
    this.selectionFailure,
  });

  final MarketAsset asset;
  final CandleSeries candles;
  final bool showVolume;
  final OrderBook? orderBook;
  final Failure? selectionFailure;

  MarketSuccess copyWith({
    MarketAsset? asset,
    CandleSeries? candles,
    bool? showVolume,
    OrderBook? orderBook,
    Failure? selectionFailure,
    bool clearSelectionFailure = false,
  }) {
    return MarketSuccess(
      asset: asset ?? this.asset,
      candles: candles ?? this.candles,
      showVolume: showVolume ?? this.showVolume,
      orderBook: orderBook ?? this.orderBook,
      selectionFailure: clearSelectionFailure
          ? null
          : selectionFailure ?? this.selectionFailure,
    );
  }

  @override
  List<Object?> get props =>
      [asset, candles, showVolume, orderBook, selectionFailure];
}

class MarketCubit extends Cubit<MarketState> {
  MarketCubit({
    required GetMarketAsset getAsset,
    required GetCandleChart getCandles,
    required WatchMarketTicks watchTicks,
    required GetOrderBook getOrderBook,
    required WatchOrderBook watchOrderBook,
    required SelectOrderBookLevel selectOrderBookLevel,
    required this.code,
  })  : _getAsset = getAsset,
        _getCandles = getCandles,
        _watchTicks = watchTicks,
        _getOrderBook = getOrderBook,
        _watchOrderBook = watchOrderBook,
        _selectOrderBookLevel = selectOrderBookLevel,
        super(const MarketLoading());

  final GetMarketAsset _getAsset;
  final GetCandleChart _getCandles;
  final WatchMarketTicks _watchTicks;
  final GetOrderBook _getOrderBook;
  final WatchOrderBook _watchOrderBook;
  final SelectOrderBookLevel _selectOrderBookLevel;
  final String code;
  StreamSubscription<Either<Failure, MarketTick>>? _ticks;
  StreamSubscription<Either<Failure, OrderBook>>? _book;

  Currency? get _currency => Currency.fromCode(code);

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
    final book = await _getOrderBook((
      currency: currency,
      depth: orderBookDefaultDepth,
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
            emit(
              MarketSuccess(
                asset: loaded,
                candles: series,
                orderBook: book.getRight().toNullable(),
              ),
            );
            _bindTicks(currency);
            _bindBook(currency);
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

  Future<BookTicketDraft?> selectLevel({
    required OrderBookSide side,
    required Money price,
  }) async {
    final currency = _currency;
    final current = state;
    if (currency == null || current is! MarketSuccess) {
      return null;
    }
    if (current.orderBook?.freshness == QuoteFreshness.disconnected) {
      emit(current.copyWith(selectionFailure: const StaleQuoteFailure()));
      return null;
    }
    final result = await _selectOrderBookLevel((
      currency: currency,
      side: side,
      price: price,
    ));
    if (isClosed) {
      return null;
    }
    final latest = state;
    if (latest is! MarketSuccess) {
      return null;
    }
    return result.fold(
      (failure) {
        emit(latest.copyWith(selectionFailure: failure));
        return null;
      },
      (draft) {
        emit(latest.copyWith(clearSelectionFailure: true));
        return draft;
      },
    );
  }

  void clearSelectionFailure() {
    final current = state;
    if (current is! MarketSuccess || current.selectionFailure == null) {
      return;
    }
    emit(current.copyWith(clearSelectionFailure: true));
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

  void _bindBook(Currency currency) {
    _book?.cancel();
    _book = _watchOrderBook((
      currency: currency,
      depth: orderBookDefaultDepth,
    )).listen((event) {
      final current = state;
      if (current is! MarketSuccess || isClosed) {
        return;
      }
      event.fold(
        (_) {},
        (book) => emit(current.copyWith(orderBook: book)),
      );
    });
  }

  @override
  Future<void> close() {
    _ticks?.cancel();
    _book?.cancel();
    return super.close();
  }
}
