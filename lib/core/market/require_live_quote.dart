import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import 'quote_freshness.dart';

Either<Failure, Unit> requireLiveQuote(QuoteFreshness freshness) {
  if (freshness != QuoteFreshness.live) {
    return Either.left(const StaleQuoteFailure());
  }
  return Either.right(unit);
}
