import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/receive_crypto.dart';

abstract class ReceiveCryptoRepository {
  Future<Either<Failure, List<ReceivableAsset>>> getAssets();

  Future<Either<Failure, List<ReceivableAsset>>> searchAssets(String query);

  Future<Either<Failure, ReceiveAddress>> getReceiveAddress({
    required Currency asset,
    String? network,
  });

  Future<Either<Failure, AssetFundingTeasers>> getTeasers(Currency asset);
}
