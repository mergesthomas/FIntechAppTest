import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/market/price_series.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/market_asset.dart';
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
  const MarketSuccess({required this.asset});

  final MarketAsset asset;

  @override
  List<Object?> get props => [asset];
}

class MarketCubit extends Cubit<MarketState> {
  MarketCubit({
    required GetMarketAsset getAsset,
    required GetPriceChart getChart,
    required this.code,
  })  : _getAsset = getAsset,
        _getChart = getChart,
        super(const MarketLoading());

  final GetMarketAsset _getAsset;
  final GetPriceChart _getChart;
  final String code;

  Currency? get _currency => Currency.tryParse(code);

  Future<void> load({ChartPeriod period = ChartPeriod.oneDay}) async {
    final currency = _currency;
    if (currency == null) {
      emit(const MarketFailure(ValidationFailure('unknown_asset')));
      return;
    }
    emit(const MarketLoading());
    final result = await _getAsset((currency: currency, period: period));
    result.fold(
      (failure) => emit(MarketFailure(failure)),
      (asset) => emit(MarketSuccess(asset: asset)),
    );
  }

  Future<void> selectPeriod(ChartPeriod period) async {
    final currency = _currency;
    final current = state;
    if (currency == null || current is! MarketSuccess) {
      await load(period: period);
      return;
    }
    final result = await _getChart((currency: currency, period: period));
    result.fold(
      (failure) => emit(MarketFailure(failure)),
      (chart) => emit(MarketSuccess(asset: current.asset.copyWith(chart: chart))),
    );
  }
}
