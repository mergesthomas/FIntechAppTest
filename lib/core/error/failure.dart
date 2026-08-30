import 'package:equatable/equatable.dart';

import '../market/quote_freshness.dart';
import '../auth/eligibility_status.dart';

/// Shared domain failures. Data maps exceptions here; Blocs map these to UI.
sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

final class SessionFailure extends Failure {
  const SessionFailure();
}

final class EligibilityFailure extends Failure {
  const EligibilityFailure(this.status);

  final EligibilityStatus status;

  @override
  List<Object?> get props => [status];
}

final class StepUpRequiredFailure extends Failure {
  const StepUpRequiredFailure();
}

final class StaleQuoteFailure extends Failure {
  const StaleQuoteFailure(this.freshness);

  final QuoteFreshness freshness;

  @override
  List<Object?> get props => [freshness];
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class ServerFailure extends Failure {
  const ServerFailure([this.reason]);

  final String? reason;

  @override
  List<Object?> get props => [reason];
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([this.reason]);

  final String? reason;

  @override
  List<Object?> get props => [reason];
}
