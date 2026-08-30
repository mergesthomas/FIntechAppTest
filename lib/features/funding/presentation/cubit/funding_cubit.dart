import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../../../core/settlement/settlement_status.dart';
import '../../../../core/usecase/use_case.dart';
import '../../domain/entities/funding.dart';
import '../../domain/usecases/funding_usecases.dart';

enum FundingSurface {
  hub,
  fiatx,
  bankRails,
  openUsd,
  receiveFiat,
  receiveAssets,
  receiveCrypto,
  buyAssets,
  buyAmount,
  buyPreview,
  buyResult,
}

sealed class FundingState extends Equatable {
  const FundingState();

  @override
  List<Object?> get props => [];
}

final class FundingLoading extends FundingState {
  const FundingLoading();
}

final class FundingEmpty extends FundingState {
  const FundingEmpty();
}

final class FundingFailure extends FundingState {
  const FundingFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class FundingReady extends FundingState {
  const FundingReady({
    required this.surface,
    required this.methods,
    this.fiatx = const [],
    this.rails = const [],
    this.accountStatus = FiatAccountStatus.none,
    this.receiveDetails,
    this.feeSchedule,
    this.receivable = const [],
    this.receiveAddress,
    this.purchasable = const [],
    this.selectedBuyAsset,
    this.spendInput = '',
    this.quote,
    this.paymentMethods = const [],
    this.selectedPaymentMethodId,
    this.buyResult,
    this.usdJob,
  });

  final FundingSurface surface;
  final List<FundingMethod> methods;
  final List<FiatxAsset> fiatx;
  final List<BankRail> rails;
  final FiatAccountStatus accountStatus;
  final FiatReceiveDetails? receiveDetails;
  final String? feeSchedule;
  final List<ReceivableAsset> receivable;
  final ReceiveAddress? receiveAddress;
  final List<PurchasableAsset> purchasable;
  final PurchasableAsset? selectedBuyAsset;
  final String spendInput;
  final BuyQuote? quote;
  final List<PaymentMethodOption> paymentMethods;
  final String? selectedPaymentMethodId;
  final Object? buyResult;
  final SettlementStatus? usdJob;

  FundingReady copyWith({
    FundingSurface? surface,
    List<FundingMethod>? methods,
    List<FiatxAsset>? fiatx,
    List<BankRail>? rails,
    FiatAccountStatus? accountStatus,
    FiatReceiveDetails? receiveDetails,
    String? feeSchedule,
    List<ReceivableAsset>? receivable,
    ReceiveAddress? receiveAddress,
    List<PurchasableAsset>? purchasable,
    PurchasableAsset? selectedBuyAsset,
    String? spendInput,
    BuyQuote? quote,
    List<PaymentMethodOption>? paymentMethods,
    String? selectedPaymentMethodId,
    Object? buyResult,
    SettlementStatus? usdJob,
  }) {
    return FundingReady(
      surface: surface ?? this.surface,
      methods: methods ?? this.methods,
      fiatx: fiatx ?? this.fiatx,
      rails: rails ?? this.rails,
      accountStatus: accountStatus ?? this.accountStatus,
      receiveDetails: receiveDetails ?? this.receiveDetails,
      feeSchedule: feeSchedule ?? this.feeSchedule,
      receivable: receivable ?? this.receivable,
      receiveAddress: receiveAddress ?? this.receiveAddress,
      purchasable: purchasable ?? this.purchasable,
      selectedBuyAsset: selectedBuyAsset ?? this.selectedBuyAsset,
      spendInput: spendInput ?? this.spendInput,
      quote: quote ?? this.quote,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedPaymentMethodId:
          selectedPaymentMethodId ?? this.selectedPaymentMethodId,
      buyResult: buyResult ?? this.buyResult,
      usdJob: usdJob ?? this.usdJob,
    );
  }

  @override
  List<Object?> get props => [
        surface,
        methods,
        fiatx,
        rails,
        accountStatus,
        receiveDetails,
        feeSchedule,
        receivable,
        receiveAddress,
        purchasable,
        selectedBuyAsset,
        spendInput,
        quote,
        paymentMethods,
        selectedPaymentMethodId,
        buyResult,
        usdJob,
      ];
}

class FundingCubit extends Cubit<FundingState> {
  FundingCubit({
    required GetFundingMethods getMethods,
    required GetFiatxAssets getFiatx,
    required GetBankRails getRails,
    required GetFiatAccountStatus getAccountStatus,
    required AcceptFiatAccountTerms acceptTerms,
    required CreatePersonalUsdAccount createUsd,
    required GetFiatReceiveDetails getReceiveDetails,
    required GetBankTransferFeeSchedule getFees,
    required GetReceivableAssets getReceivable,
    required GetReceiveAddress getReceiveAddress,
    required GetPurchasableAssets getPurchasable,
    required GetBuyQuote getBuyQuote,
    required GetPaymentMethods getPaymentMethods,
    required SubmitBuyCrypto submitBuy,
  })  : _getMethods = getMethods,
        _getFiatx = getFiatx,
        _getRails = getRails,
        _getAccountStatus = getAccountStatus,
        _acceptTerms = acceptTerms,
        _createUsd = createUsd,
        _getReceiveDetails = getReceiveDetails,
        _getFees = getFees,
        _getReceivable = getReceivable,
        _getReceiveAddress = getReceiveAddress,
        _getPurchasable = getPurchasable,
        _getBuyQuote = getBuyQuote,
        _getPaymentMethods = getPaymentMethods,
        _submitBuy = submitBuy,
        super(const FundingLoading());

  final GetFundingMethods _getMethods;
  final GetFiatxAssets _getFiatx;
  final GetBankRails _getRails;
  final GetFiatAccountStatus _getAccountStatus;
  final AcceptFiatAccountTerms _acceptTerms;
  final CreatePersonalUsdAccount _createUsd;
  final GetFiatReceiveDetails _getReceiveDetails;
  final GetBankTransferFeeSchedule _getFees;
  final GetReceivableAssets _getReceivable;
  final GetReceiveAddress _getReceiveAddress;
  final GetPurchasableAssets _getPurchasable;
  final GetBuyQuote _getBuyQuote;
  final GetPaymentMethods _getPaymentMethods;
  final SubmitBuyCrypto _submitBuy;

  FundingReady? get _ready => state is FundingReady ? state as FundingReady : null;

  Future<void> load() async {
    emit(const FundingLoading());
    final result = await _getMethods(const NoParams());
    result.fold(
      (failure) => emit(FundingFailure(failure)),
      (methods) => emit(
        methods.isEmpty
            ? const FundingEmpty()
            : FundingReady(surface: FundingSurface.hub, methods: methods),
      ),
    );
  }

  Future<void> openBank() async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final assets = await _getFiatx(const NoParams());
    assets.fold(
      (failure) => emit(FundingFailure(failure)),
      (fiatx) => emit(
        current.copyWith(surface: FundingSurface.fiatx, fiatx: fiatx),
      ),
    );
  }

  Future<void> openRails(Currency asset) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final rails = await _getRails(asset);
    final fees = await _getFees(asset);
    rails.fold(
      (failure) => emit(FundingFailure(failure)),
      (list) => emit(
        current.copyWith(
          surface: FundingSurface.bankRails,
          rails: list,
          feeSchedule: fees.getRight().toNullable(),
        ),
      ),
    );
  }

  Future<void> openUsdAccount() async {
    final current = _ready;
    if (current == null) {
      return;
    }
    await _acceptTerms(const NoParams());
    final status = await _getAccountStatus(const NoParams());
    status.fold(
      (failure) => emit(FundingFailure(failure)),
      (account) => emit(
        current.copyWith(
          surface: FundingSurface.openUsd,
          accountStatus: account,
        ),
      ),
    );
  }

  Future<void> createUsd({required String requestId, required bool stepUp}) async {
    final result = await _createUsd((requestId: requestId, stepUp: stepUp));
    final current = _ready;
    result.fold(
      (failure) => emit(FundingFailure(failure)),
      (job) {
        if (current != null) {
          emit(current.copyWith(usdJob: job, accountStatus: FiatAccountStatus.inFlight));
        }
      },
    );
  }

  Future<void> openReceiveFiat(Currency asset, String rail) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final details = await _getReceiveDetails((asset: asset, rail: rail));
    details.fold(
      (failure) => emit(FundingFailure(failure)),
      (d) => emit(
        current.copyWith(surface: FundingSurface.receiveFiat, receiveDetails: d),
      ),
    );
  }

  Future<void> openReceiveCrypto({String query = ''}) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final assets = await _getReceivable(query);
    assets.fold(
      (failure) => emit(FundingFailure(failure)),
      (list) => emit(
        current.copyWith(
          surface: FundingSurface.receiveAssets,
          receivable: list,
        ),
      ),
    );
  }

  Future<void> showReceiveAddress(Currency currency) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final address = await _getReceiveAddress(currency);
    address.fold(
      (failure) => emit(FundingFailure(failure)),
      (a) => emit(
        current.copyWith(
          surface: FundingSurface.receiveCrypto,
          receiveAddress: a,
        ),
      ),
    );
  }

  Future<void> openBuyAsset(Currency currency) async {
    await openBuy();
    final current = _ready;
    if (current == null) {
      return;
    }
    for (final asset in current.purchasable) {
      if (asset.currency == currency) {
        selectBuyAsset(asset);
        return;
      }
    }
  }

  Future<void> openBuy({String query = ''}) async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final assets = await _getPurchasable(query);
    assets.fold(
      (failure) => emit(FundingFailure(failure)),
      (list) => emit(
        current.copyWith(surface: FundingSurface.buyAssets, purchasable: list),
      ),
    );
  }

  void selectBuyAsset(PurchasableAsset asset) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(
      current.copyWith(
        surface: FundingSurface.buyAmount,
        selectedBuyAsset: asset,
        spendInput: '',
      ),
    );
  }

  void typeSpend(String value) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(spendInput: value));
  }

  Future<void> loadPaymentMethods() async {
    final current = _ready;
    if (current == null) {
      return;
    }
    final methods = await _getPaymentMethods(const NoParams());
    methods.fold(
      (failure) => emit(FundingFailure(failure)),
      (list) => emit(current.copyWith(paymentMethods: list)),
    );
  }

  void selectPaymentMethod(String id) {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(selectedPaymentMethodId: id));
  }

  Future<void> previewBuy() async {
    final current = _ready;
    final asset = current?.selectedBuyAsset;
    if (current == null || asset == null) {
      return;
    }
    late final Money spend;
    try {
      spend = Money.parse(
        current.spendInput.isEmpty ? '0' : current.spendInput,
        Currency.usd,
      );
    } on FormatException {
      emit(const FundingFailure(ValidationFailure('amount_invalid')));
      return;
    }
    final quote = await _getBuyQuote((asset: asset.currency, spend: spend));
    quote.fold(
      (failure) => emit(FundingFailure(failure)),
      (q) => emit(current.copyWith(surface: FundingSurface.buyPreview, quote: q)),
    );
  }

  Future<void> confirmBuy({
    required String requestId,
    required bool stepUp,
  }) async {
    final current = _ready;
    final quote = current?.quote;
    if (current == null || quote == null) {
      return;
    }
    final result = await _submitBuy((
      requestId: requestId,
      quoteId: quote.quoteId,
      paymentMethodId: current.selectedPaymentMethodId ?? 'apple_pay',
      amount: quote.spend,
      frequency: 'Instant',
      stepUp: stepUp,
    ));
    result.fold(
      (failure) => emit(
        current.copyWith(surface: FundingSurface.buyResult, buyResult: failure),
      ),
      (submit) => emit(
        current.copyWith(surface: FundingSurface.buyResult, buyResult: submit),
      ),
    );
  }

  void backToHub() {
    final current = _ready;
    if (current == null) {
      return;
    }
    emit(current.copyWith(surface: FundingSurface.hub));
  }
}
