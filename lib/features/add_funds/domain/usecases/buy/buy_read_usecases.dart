import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/money/money.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/buy_crypto.dart';
import '../../repositories/buy_crypto_repository.dart';

final class GetPurchasableAssets
    implements UseCase<List<PurchasableAsset>, NoParams> {
  GetPurchasableAssets(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, List<PurchasableAsset>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _buy.getAssets();
  }
}

final class SearchPurchasableAssetsParams extends Equatable {
  const SearchPurchasableAssetsParams(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SearchPurchasableAssets
    implements UseCase<List<PurchasableAsset>, SearchPurchasableAssetsParams> {
  SearchPurchasableAssets(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, List<PurchasableAsset>>> call(
    SearchPurchasableAssetsParams params,
  ) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _buy.searchAssets(params.query.trim());
  }
}

final class GetBuyQuoteParams extends Equatable {
  const GetBuyQuoteParams({
    required this.fiatIn,
    required this.cryptoCode,
    required this.frequency,
  });

  final Money fiatIn;
  final String cryptoCode;
  final PurchaseFrequency frequency;

  @override
  List<Object?> get props => [fiatIn, cryptoCode, frequency];
}

final class GetBuyQuote implements UseCase<BuyQuote, GetBuyQuoteParams> {
  GetBuyQuote(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, BuyQuote>> call(GetBuyQuoteParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    if (!params.fiatIn.isPositive) {
      return Either.left(const ValidationFailure('amount_must_be_positive'));
    }
    return _buy.getQuote(
      fiatIn: params.fiatIn,
      cryptoCode: params.cryptoCode,
      frequency: params.frequency,
    );
  }
}

final class GetPaymentMethods
    implements UseCase<List<PaymentMethod>, NoParams> {
  GetPaymentMethods(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, List<PaymentMethod>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _buy.getPaymentMethods();
  }
}

final class GetPurchaseFrequencies
    implements UseCase<List<PurchaseFrequency>, NoParams> {
  GetPurchaseFrequencies(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, List<PurchaseFrequency>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _buy.getFrequencies();
  }
}

final class GetEmptyBalances implements UseCase<List<EmptyBalance>, NoParams> {
  GetEmptyBalances(this._guards, this._buy);

  final AccessGuards _guards;
  final BuyCryptoRepository _buy;

  @override
  Future<Either<Failure, List<EmptyBalance>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _buy.getEmptyBalances();
  }
}
