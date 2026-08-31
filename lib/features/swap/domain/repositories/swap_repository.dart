import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../entities/swap.dart';

abstract class SwapRepository {
  Future<Either<Failure, List<SwapWallet>>> getWallets();
  Future<Either<Failure, List<SwapAsset>>> searchAssets(String query);
  Stream<Either<Failure, SwapRate>> watchRate({
    required Currency from,
    required Currency to,
  });
  Future<Either<Failure, SwapQuote>> getQuote(SwapQuoteRequest request);
  Future<Either<Failure, SwapQuote>> getQuoteById(String quoteId);
  Future<Either<Failure, SwapSubmit>> submit({
    required String requestId,
    required String quoteId,
    required SwapWallet wallet,
  });
}
