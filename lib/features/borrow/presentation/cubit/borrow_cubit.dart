import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/borrow.dart';
import '../../domain/usecases/borrow_usecases.dart';

enum BorrowSurface { loans, collateral, optimization, preview, repay, result }

sealed class BorrowState extends Equatable {
  const BorrowState();

  @override
  List<Object?> get props => [];
}

final class BorrowLoading extends BorrowState {
  const BorrowLoading();
}

final class BorrowEmpty extends BorrowState {
  const BorrowEmpty();
}

final class BorrowFailure extends BorrowState {
  const BorrowFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class BorrowReady extends BorrowState {
  const BorrowReady({
    required this.surface,
    required this.overview,
    required this.products,
    this.collateral = const [],
    this.optimization,
    this.quote,
    this.repayInput = '',
    this.result,
  });

  final BorrowSurface surface;
  final LoansOverview overview;
  final List<LoanProduct> products;
  final List<CollateralAsset> collateral;
  final CreditLineOptimization? optimization;
  final BorrowQuote? quote;
  final String repayInput;
  final Object? result;

  BorrowReady copyWith({
    BorrowSurface? surface,
    LoansOverview? overview,
    List<LoanProduct>? products,
    List<CollateralAsset>? collateral,
    CreditLineOptimization? optimization,
    BorrowQuote? quote,
    String? repayInput,
    Object? result,
  }) {
    return BorrowReady(
      surface: surface ?? this.surface,
      overview: overview ?? this.overview,
      products: products ?? this.products,
      collateral: collateral ?? this.collateral,
      optimization: optimization ?? this.optimization,
      quote: quote ?? this.quote,
      repayInput: repayInput ?? this.repayInput,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
        surface,
        overview,
        products,
        collateral,
        optimization,
        quote,
        repayInput,
        result,
      ];
}

class BorrowCubit extends Cubit<BorrowState> {
  BorrowCubit({
    required GetAllLoansOverview getOverview,
    required GetLoanProducts getProducts,
    required GetCollateralAssets getCollateral,
    required GetCreditLineOptimization getOptimization,
    required UpdateCreditLineOptimization updateOptimization,
    required GetBorrowQuote getQuote,
    required SubmitBorrow submitBorrow,
    required SubmitRepay submitRepay,
  })  : _getOverview = getOverview,
        _getProducts = getProducts,
        _getCollateral = getCollateral,
        _getOptimization = getOptimization,
        _updateOptimization = updateOptimization,
        _getQuote = getQuote,
        _submitBorrow = submitBorrow,
        _submitRepay = submitRepay,
        super(const BorrowLoading());

  final GetAllLoansOverview _getOverview;
  final GetLoanProducts _getProducts;
  final GetCollateralAssets _getCollateral;
  final GetCreditLineOptimization _getOptimization;
  final UpdateCreditLineOptimization _updateOptimization;
  final GetBorrowQuote _getQuote;
  final SubmitBorrow _submitBorrow;
  final SubmitRepay _submitRepay;

  BorrowReady? get _ready => state is BorrowReady ? state as BorrowReady : null;

  Future<void> load() async {
    emit(const BorrowLoading());
    final overview = await _getOverview(const NoParams());
    await overview.fold((failure) async => emit(BorrowFailure(failure)), (
      o,
    ) async {
      final products = await _getProducts(const NoParams());
      products.fold(
        (failure) => emit(BorrowFailure(failure)),
        (list) => emit(
          list.isEmpty
              ? const BorrowEmpty()
              : BorrowReady(
                  surface: BorrowSurface.loans,
                  overview: o,
                  products: list,
                ),
        ),
      );
    });
  }

  Future<void> openCollateral() async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final result = await _getCollateral(const NoParams());
    result.fold(
      (failure) => emit(BorrowFailure(failure)),
      (list) => emit(
        current.copyWith(surface: BorrowSurface.collateral, collateral: list),
      ),
    );
  }

  Future<void> openOptimization() async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final result = await _getOptimization(const NoParams());
    result.fold(
      (failure) => emit(BorrowFailure(failure)),
      (flags) => emit(
        current.copyWith(
          surface: BorrowSurface.optimization,
          optimization: flags,
        ),
      ),
    );
  }

  Future<void> saveOptimization({
    required CreditLineOptimization flags,
    required String requestId,
    required bool stepUp,
  }) async {
    final current = _ready;
    final result = await _updateOptimization((
      requestId: requestId,
      stepUp: stepUp,
      flags: flags,
    ));
    result.fold(
      (failure) => emit(
        current?.copyWith(surface: BorrowSurface.result, result: failure) ??
            BorrowFailure(failure),
      ),
      (status) => emit(
        current?.copyWith(
              surface: BorrowSurface.result,
              result: status,
              optimization: flags,
            ) ??
            BorrowFailure(const ServerFailure()),
      ),
    );
  }

  Future<void> previewBorrow(String productId) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final quote = await _getQuote((
      productId: productId,
      amount: Money.parse('100', Currency.usdc),
    ));
    quote.fold(
      (failure) => emit(BorrowFailure(failure)),
      (q) => emit(current.copyWith(surface: BorrowSurface.preview, quote: q)),
    );
  }

  Future<void> confirmBorrow({
    required String requestId,
    required bool stepUp,
  }) async {
    final current = _ready;
    final quote = current?.quote;
    if (current == null || quote == null) {
      return;
    }
    final result = await _submitBorrow((
      requestId: requestId,
      quoteId: quote.quoteId,
      stepUp: stepUp,
    ));
    result.fold(
      (failure) =>
          emit(current.copyWith(surface: BorrowSurface.result, result: failure)),
      (submit) =>
          emit(current.copyWith(surface: BorrowSurface.result, result: submit)),
    );
  }

  void openRepay() {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(surface: BorrowSurface.repay, repayInput: ''));
  }

  void typeRepay(String value) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(repayInput: value));
  }

  Future<void> confirmRepay({
    required String requestId,
    required bool stepUp,
  }) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    late final Money amount;
    try {
      amount = Money.parse(
        current.repayInput.isEmpty ? '0' : current.repayInput,
        Currency.xusd,
      );
    } on FormatException {
      emit(const BorrowFailure(ValidationFailure('amount_invalid')));
      return;
    }
    final result = await _submitRepay((
      requestId: requestId,
      loanId: 'classic',
      amount: amount,
      stepUp: stepUp,
    ));
    result.fold(
      (failure) =>
          emit(current.copyWith(surface: BorrowSurface.result, result: failure)),
      (submit) =>
          emit(current.copyWith(surface: BorrowSurface.result, result: submit)),
    );
  }

  void backToLoans() {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(surface: BorrowSurface.loans));
  }
}
