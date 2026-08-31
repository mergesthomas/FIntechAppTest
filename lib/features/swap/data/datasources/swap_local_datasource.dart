import '../../domain/entities/swap.dart';

final class SwapLocalDataSource {
  final Map<String, SwapQuote> quotes = {};

  List<SwapWallet> wallets() => [SwapWallet.savings];

  SwapQuote store(SwapQuote quote) {
    quotes[quote.quoteId] = quote;
    return quote;
  }
}
