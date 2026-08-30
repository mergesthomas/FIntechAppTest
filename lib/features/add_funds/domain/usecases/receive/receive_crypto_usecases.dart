import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/auth/access_guards.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/money/currency.dart';
import '../../../../../core/usecase/use_case.dart';
import '../../entities/receive_crypto.dart';
import '../../repositories/receive_crypto_repository.dart';

final class GetReceivableAssets
    implements UseCase<List<ReceivableAsset>, NoParams> {
  GetReceivableAssets(this._guards, this._receive);

  final AccessGuards _guards;
  final ReceiveCryptoRepository _receive;

  @override
  Future<Either<Failure, List<ReceivableAsset>>> call(NoParams params) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _receive.getAssets();
  }
}

final class SearchReceivableAssetsParams extends Equatable {
  const SearchReceivableAssetsParams(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SearchReceivableAssets
    implements UseCase<List<ReceivableAsset>, SearchReceivableAssetsParams> {
  SearchReceivableAssets(this._guards, this._receive);

  final AccessGuards _guards;
  final ReceiveCryptoRepository _receive;

  @override
  Future<Either<Failure, List<ReceivableAsset>>> call(
    SearchReceivableAssetsParams params,
  ) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _receive.searchAssets(params.query.trim());
  }
}

final class GetReceiveAddressParams extends Equatable {
  const GetReceiveAddressParams({
    required this.asset,
    this.network,
  });

  final Currency asset;
  final String? network;

  @override
  List<Object?> get props => [asset, network];
}

final class GetReceiveAddress
    implements UseCase<ReceiveAddress, GetReceiveAddressParams> {
  GetReceiveAddress(this._guards, this._receive);

  final AccessGuards _guards;
  final ReceiveCryptoRepository _receive;

  @override
  Future<Either<Failure, ReceiveAddress>> call(
    GetReceiveAddressParams params,
  ) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _receive.getReceiveAddress(
      asset: params.asset,
      network: params.network,
    );
  }
}

final class GetAssetFundingTeasers
    implements UseCase<AssetFundingTeasers, Currency> {
  GetAssetFundingTeasers(this._guards, this._receive);

  final AccessGuards _guards;
  final ReceiveCryptoRepository _receive;

  @override
  Future<Either<Failure, AssetFundingTeasers>> call(Currency asset) async {
    final session = await _guards.requireSession();
    if (session.isLeft()) {
      return session.hideRight();
    }
    return _receive.getTeasers(asset);
  }
}
