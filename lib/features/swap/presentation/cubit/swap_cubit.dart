import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/swap.dart';
import '../../domain/usecases/swap_usecases.dart';

enum SwapSurface { ticket, preview, result }

enum SwapInputField { payAmount, limitPrice, takeProfit, stopLoss }

sealed class SwapState extends Equatable {
  const SwapState();

  @override
  List<Object?> get props => [];
}

final class SwapLoading extends SwapState {
  const SwapLoading();
}

final class SwapEmpty extends SwapState {
  const SwapEmpty();
}

final class SwapFailure extends SwapState {
  const SwapFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class SwapReady extends SwapState {
  const SwapReady({
    required this.surface,
    required this.assets,
    required this.orderTypes,
    this.orderType = SwapOrderType.instant,
    this.from = Currency.usdc,
    this.to = Currency.doge,
    this.amountInput = '',
    this.limitInput = '',
    this.tpInput = '',
    this.slInput = '',
    this.inputField = SwapInputField.payAmount,
    this.rate,
    this.quote,
    this.result,
  });

  final SwapSurface surface;
  final List<SwapAsset> assets;
  final List<SwapOrderType> orderTypes;
  final SwapOrderType orderType;
  final Currency from;
  final Currency to;
  final String amountInput;
  final String limitInput;
  final String tpInput;
  final String slInput;
  final SwapInputField inputField;
  final SwapRate? rate;
  final SwapQuote? quote;
  final Object? result;

  Money? get fromBalance {
    for (final asset in assets) {
      if (asset.currency == from) {
        return asset.balance;
      }
    }
    return null;
  }

  Money? get toBalance {
    for (final asset in assets) {
      if (asset.currency == to) {
        return asset.balance;
      }
    }
    return null;
  }

  SwapReady copyWith({
    SwapSurface? surface,
    List<SwapAsset>? assets,
    List<SwapOrderType>? orderTypes,
    SwapOrderType? orderType,
    Currency? from,
    Currency? to,
    String? amountInput,
    String? limitInput,
    String? tpInput,
    String? slInput,
    SwapInputField? inputField,
    SwapRate? rate,
    SwapQuote? quote,
    Object? result,
    bool clearQuote = false,
    bool clearRate = false,
    bool clearResult = false,
  }) {
    return SwapReady(
      surface: surface ?? this.surface,
      assets: assets ?? this.assets,
      orderTypes: orderTypes ?? this.orderTypes,
      orderType: orderType ?? this.orderType,
      from: from ?? this.from,
      to: to ?? this.to,
      amountInput: amountInput ?? this.amountInput,
      limitInput: limitInput ?? this.limitInput,
      tpInput: tpInput ?? this.tpInput,
      slInput: slInput ?? this.slInput,
      inputField: inputField ?? this.inputField,
      rate: clearRate ? null : rate ?? this.rate,
      quote: clearQuote ? null : quote ?? this.quote,
      result: clearResult ? null : result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
        surface,
        assets,
        orderTypes,
        orderType,
        from,
        to,
        amountInput,
        limitInput,
        tpInput,
        slInput,
        inputField,
        rate,
        quote,
        result,
      ];
}

class SwapCubit extends Cubit<SwapState> {
  SwapCubit({
    required SearchSwapAssets searchAssets,
    required GetSwapOrderTypes getOrderTypes,
    required WatchSwapRate watchRate,
    required GetSwapQuote getQuote,
    required SubmitSwap submit,
  })  : _searchAssets = searchAssets,
        _getOrderTypes = getOrderTypes,
        _watchRate = watchRate,
        _getQuote = getQuote,
        _submit = submit,
        super(const SwapLoading());

  final SearchSwapAssets _searchAssets;
  final GetSwapOrderTypes _getOrderTypes;
  final WatchSwapRate _watchRate;
  final GetSwapQuote _getQuote;
  final SubmitSwap _submit;

  StreamSubscription<Either<Failure, SwapRate>>? _rateSub;

  SwapReady? get _ready => state is SwapReady ? state as SwapReady : null;

  Future<void> load() async {
    emit(const SwapLoading());
    final types = await _getOrderTypes(const NoParams());
    await types.fold((failure) async => emit(SwapFailure(failure)), (list) async {
      final assets = await _searchAssets('');
      assets.fold(
        (failure) => emit(SwapFailure(failure)),
        (found) {
          if (found.isEmpty) {
            emit(const SwapEmpty());
            return;
          }
          final ready = SwapReady(
            surface: SwapSurface.ticket,
            assets: found,
            orderTypes: list,
          );
          emit(ready);
          _listenRate(ready);
        },
      );
    });
  }

  void selectOrderType(SwapOrderType type) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(
      current.copyWith(
        orderType: type,
        inputField: SwapInputField.payAmount,
        clearQuote: true,
      ),
    );
  }

  void focusField(SwapInputField field) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(inputField: field));
  }

  void typeAmount(String value) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(_writeField(current, value));
  }

  void appendKey(String key) {
    final current = _ready;
    if (current == null) {
      return;
    }
    final existing = _fieldValue(current);
    if (key == '.') {
      if (existing.contains('.')) {
        return;
      }
      emit(_writeField(current, existing.isEmpty ? '0.' : '$existing.'));
      return;
    }
    emit(_writeField(current, '$existing$key'));
  }

  void backspace() {
    final current = _ready;
    if (current == null) {
      return;
    }
    final existing = _fieldValue(current);
    if (existing.isEmpty) {
      return;
    }
    emit(_writeField(current, existing.substring(0, existing.length - 1)));
  }

  void setPercent(int percent) {
    final current = _ready;
    if (current == null) {
      return;
    }
    final balance = current.fromBalance;
    if (balance == null || !balance.isPositive) {
      emit(
        current.copyWith(
          amountInput: '',
          inputField: SwapInputField.payAmount,
        ),
      );
      return;
    }
    final share = (Decimal.fromInt(percent) / Decimal.fromInt(100))
        .toDecimal(scaleOnInfinitePrecision: 18);
    final amount = Money.fromDecimal(balance.amount * share, current.from);
    emit(
      current.copyWith(
        amountInput: amount.amount.toString(),
        inputField: SwapInputField.payAmount,
        clearQuote: true,
      ),
    );
  }

  void flip() {
    final current = _ready;
    if (current == null) {
      return;
    }
    final next = current.copyWith(
      from: current.to,
      to: current.from,
      amountInput: '',
      limitInput: '',
      tpInput: '',
      slInput: '',
      inputField: SwapInputField.payAmount,
      clearQuote: true,
      clearRate: true,
    );
    emit(next);
    _listenRate(next);
  }

  void selectFrom(Currency currency) {
    final current = _ready;
    if (current == null || currency == current.to) {
      return;
    }
    final next = current.copyWith(
      from: currency,
      amountInput: '',
      limitInput: '',
      tpInput: '',
      slInput: '',
      clearQuote: true,
      clearRate: true,
    );
    emit(next);
    _listenRate(next);
  }

  void selectTo(Currency currency) {
    final current = _ready;
    if (current == null || currency == current.from) {
      return;
    }
    final next = current.copyWith(
      to: currency,
      clearQuote: true,
      clearRate: true,
    );
    emit(next);
    _listenRate(next);
  }

  Future<void> preview() async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final amount = _parse(current.amountInput, current.from);
    if (amount == null) {
      emit(const SwapFailure(ValidationFailure('amount_invalid')));
      return;
    }
    final quote = await _getQuote(
      SwapQuoteRequest(
        from: current.from,
        to: current.to,
        amount: amount,
        type: current.orderType,
        limitPrice: current.orderType == SwapOrderType.limit
            ? _parse(current.limitInput, current.from)
            : null,
        takeProfit: current.orderType == SwapOrderType.trigger
            ? _parse(current.tpInput, current.from)
            : null,
        stopLoss: current.orderType == SwapOrderType.trigger
            ? _parse(current.slInput, current.from)
            : null,
      ),
    );
    if (isClosed) {
      return;
    }
    quote.fold(
      (failure) => emit(SwapFailure(failure)),
      (q) => emit(current.copyWith(surface: SwapSurface.preview, quote: q)),
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
      wallet: SwapWallet.savings,
      stepUp: stepUp,
    ));
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) =>
          emit(current.copyWith(surface: SwapSurface.result, result: failure)),
      (submit) =>
          emit(current.copyWith(surface: SwapSurface.result, result: submit)),
    );
  }

  void backToTicket() {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(
      current.copyWith(
        surface: SwapSurface.ticket,
        clearQuote: true,
        clearResult: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _rateSub?.cancel();
    return super.close();
  }

  void _listenRate(SwapReady current) {
    _rateSub?.cancel();
    _rateSub = _watchRate((from: current.from, to: current.to)).listen((event) {
      if (isClosed) {
        return;
      }
      final ready = _ready;
      if (ready == null) {
        return;
      }
      event.fold(
        (_) => emit(ready.copyWith(clearRate: true)),
        (rate) => emit(ready.copyWith(rate: rate)),
      );
    });
  }

  String _fieldValue(SwapReady current) {
    return switch (current.inputField) {
      SwapInputField.payAmount => current.amountInput,
      SwapInputField.limitPrice => current.limitInput,
      SwapInputField.takeProfit => current.tpInput,
      SwapInputField.stopLoss => current.slInput,
    };
  }

  SwapReady _writeField(SwapReady current, String value) {
    return switch (current.inputField) {
      SwapInputField.payAmount =>
        current.copyWith(amountInput: value, clearQuote: true),
      SwapInputField.limitPrice =>
        current.copyWith(limitInput: value, clearQuote: true),
      SwapInputField.takeProfit =>
        current.copyWith(tpInput: value, clearQuote: true),
      SwapInputField.stopLoss =>
        current.copyWith(slInput: value, clearQuote: true),
    };
  }

  Money? _parse(String input, Currency currency) {
    if (input.isEmpty) {
      return null;
    }
    try {
      return Money.parse(input, currency);
    } on FormatException {
      return null;
    }
  }
}
