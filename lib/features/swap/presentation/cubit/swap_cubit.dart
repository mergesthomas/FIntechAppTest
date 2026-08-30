import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/swap.dart';
import '../../domain/usecases/swap_usecases.dart';

enum SwapSurface { ticket, preview, result }

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
    required this.wallets,
    required this.assets,
    this.wallet = SwapWallet.savings,
    this.from = Currency.nexo,
    this.to = Currency.eurx,
    this.amountInput = '',
    this.quote,
    this.result,
  });

  final SwapSurface surface;
  final List<SwapWallet> wallets;
  final List<SwapAsset> assets;
  final SwapWallet wallet;
  final Currency from;
  final Currency to;
  final String amountInput;
  final SwapQuote? quote;
  final Object? result;

  SwapReady copyWith({
    SwapSurface? surface,
    List<SwapWallet>? wallets,
    List<SwapAsset>? assets,
    SwapWallet? wallet,
    Currency? from,
    Currency? to,
    String? amountInput,
    SwapQuote? quote,
    Object? result,
  }) {
    return SwapReady(
      surface: surface ?? this.surface,
      wallets: wallets ?? this.wallets,
      assets: assets ?? this.assets,
      wallet: wallet ?? this.wallet,
      from: from ?? this.from,
      to: to ?? this.to,
      amountInput: amountInput ?? this.amountInput,
      quote: quote ?? this.quote,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props =>
      [surface, wallets, assets, wallet, from, to, amountInput, quote, result];
}

class SwapCubit extends Cubit<SwapState> {
  SwapCubit({
    required GetSwapWallets getWallets,
    required SearchSwapAssets searchAssets,
    required GetSwapQuote getQuote,
    required SubmitSwap submit,
  })  : _getWallets = getWallets,
        _searchAssets = searchAssets,
        _getQuote = getQuote,
        _submit = submit,
        super(const SwapLoading());

  final GetSwapWallets _getWallets;
  final SearchSwapAssets _searchAssets;
  final GetSwapQuote _getQuote;
  final SubmitSwap _submit;

  SwapReady? get _ready => state is SwapReady ? state as SwapReady : null;

  Future<void> load() async {
    emit(const SwapLoading());
    final wallets = await _getWallets(const NoParams());
    await wallets.fold((failure) async => emit(SwapFailure(failure)), (w) async {
      final assets = await _searchAssets('');
      assets.fold(
        (failure) => emit(SwapFailure(failure)),
        (list) => emit(
          list.isEmpty
              ? const SwapEmpty()
              : SwapReady(
                  surface: SwapSurface.ticket,
                  wallets: w,
                  assets: list,
                ),
        ),
      );
    });
  }

  void typeAmount(String value) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(amountInput: value));
  }

  void selectWallet(SwapWallet wallet) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(wallet: wallet));
  }

  Future<void> preview() async {
    final current = _ready;
    if (current == null) {
      return;
    }
    late final Money amount;
    try {
      amount = Money.parse(
        current.amountInput.isEmpty ? '0' : current.amountInput,
        current.from,
      );
    } on FormatException {
      emit(const SwapFailure(ValidationFailure('amount_invalid')));
      return;
    }
    final quote = await _getQuote((
      from: current.from,
      to: current.to,
      amount: amount,
      wallet: current.wallet,
    ));
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
      wallet: current.wallet,
      stepUp: stepUp,
    ));
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
    emit(current.copyWith(surface: SwapSurface.ticket));
  }
}
