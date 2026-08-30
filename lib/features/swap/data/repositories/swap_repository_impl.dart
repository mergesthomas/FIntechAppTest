import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/swap.dart';
import '../../domain/repositories/swap_repository.dart';
import '../datasources/swap_local_datasource.dart';

final class SwapRepositoryImpl implements SwapRepository {
  SwapRepositoryImpl(this._local);

  final SwapLocalDataSource _local;

  @override
  Future<Either<Failure, List<SwapWallet>>> getWallets() async {
    return Either.right(_local.wallets());
  }

  @override
  Future<Either<Failure, List<SwapAsset>>> searchAssets(String query) async {
    return Either.right(_local.assets(query));
  }

  @override
  Future<Either<Failure, SwapQuote>> getQuote({
    required Currency from,
    required Currency to,
    required Money amount,
    required SwapWallet wallet,
  }) async {
    return Either.right(
      _local.quote(from: from, to: to, amount: amount, wallet: wallet),
    );
  }

  @override
  Future<Either<Failure, SwapQuote>> getQuoteById(String quoteId) async {
    final quote = _local.quotes[quoteId];
    if (quote == null) {
      return Either.left(const ValidationFailure('quote_not_found'));
    }
    return Either.right(quote);
  }

  @override
  Future<Either<Failure, SwapSubmit>> submit({
    required String requestId,
    required String quoteId,
    required SwapWallet wallet,
  }) async {
    return Either.right(
      _local.submit(requestId: requestId, quoteId: quoteId, wallet: wallet),
    );
  }
}
