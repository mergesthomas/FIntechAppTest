import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import '../market/quote_freshness.dart';
import 'auth_port.dart';
import 'eligibility_status.dart';
import 'product_area.dart';

/// Shared session / KYC / step-up / quote gates for money-moving use cases.
final class AccessGuards {
  const AccessGuards(this.auth);

  final AuthPort auth;

  Future<Either<Failure, Unit>> requireSession() async {
    final result = await auth.hasValidSession();
    return result.flatMap((ok) {
      if (ok) {
        return Either<Failure, Unit>.right(unit);
      }
      return Either<Failure, Unit>.left(const SessionFailure());
    });
  }

  Future<Either<Failure, Unit>> requireApproved(ProductArea area) async {
    final session = await requireSession();
    if (session.isLeft()) {
      return session;
    }
    final eligibility = await auth.eligibility(area);
    return eligibility.flatMap((status) {
      if (status == EligibilityStatus.approved) {
        return Either<Failure, Unit>.right(unit);
      }
      return Either<Failure, Unit>.left(EligibilityFailure(status));
    });
  }

  Either<Failure, Unit> requireStepUp(bool verified) {
    if (verified) {
      return Either<Failure, Unit>.right(unit);
    }
    return Either<Failure, Unit>.left(const StepUpRequiredFailure());
  }

  Either<Failure, Unit> requireLiveQuote(QuoteFreshness freshness) {
    if (freshness == QuoteFreshness.live) {
      return Either<Failure, Unit>.right(unit);
    }
    return Either<Failure, Unit>.left(StaleQuoteFailure(freshness));
  }
}
