import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../entities/swap.dart';

abstract class SwapRepository {
  Future<Either<Failure, List<SwapWallet>>> getWallets();
  Future<Either<Failure, List<SwapAsset>>> searchAssets(String query);
  Future<Either<Failure, SwapQuote>> getQuote({
    required Currency from,
    required Currency to,
    required Money amount,
    required SwapWallet wallet,
  });
  Future<Either<Failure, SwapQuote>> getQuoteById(String quoteId);
  Future<Either<Failure, SwapSubmit>> submit({
    required String requestId,
    required String quoteId,
    required SwapWallet wallet,
  });
}
