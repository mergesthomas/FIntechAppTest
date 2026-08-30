import 'package:decimal/decimal.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import '../money/currency.dart';
import '../money/money.dart';
import 'market_feed.dart';
import 'market_quote.dart';
import 'quote_freshness.dart';

Either<Failure, ({Money to, QuoteFreshness freshness})> convertWithFeed({
  required MarketFeed feed,
  required Money from,
  required Currency to,
}) {
  final fromQuote = feed.quoteFor(from.currency);
  final toQuote = feed.quoteFor(to);
  if (fromQuote == null || toQuote == null) {
    return Either.left(const StaleQuoteFailure());
  }
  if (toQuote.price.amount == Decimal.zero) {
    return Either.left(const ValidationFailure('quote_invalid'));
  }
  final rate = (fromQuote.price.amount / toQuote.price.amount).toDecimal(
    scaleOnInfinitePrecision: 18,
  );
  return Either.right((
    to: from.convert(rate, to),
    freshness: combineFreshness(fromQuote.freshness, toQuote.freshness),
  ));
}

Either<Failure, ({Money receive, QuoteFreshness freshness})> buyWithUsd({
  required MarketFeed feed,
  required Currency asset,
  required Money spend,
}) {
  final price = feed.usdPrice(asset);
  final quote = feed.quoteFor(asset);
  if (price == null || quote == null || price.amount == Decimal.zero) {
    return Either.left(const StaleQuoteFailure());
  }
  final receive = Money.fromDecimal(
    (spend.amount / price.amount).toDecimal(scaleOnInfinitePrecision: 18),
    asset,
  );
  return Either.right((receive: receive, freshness: quote.freshness));
}
