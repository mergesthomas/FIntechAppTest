import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

final class SessionFailure extends Failure {
  const SessionFailure();
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class AuthFailure extends Failure {
  const AuthFailure(this.reason);

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

final class EligibilityFailure extends Failure {
  const EligibilityFailure();
}

final class StaleQuoteFailure extends Failure {
  const StaleQuoteFailure();
}

final class StepUpFailure extends Failure {
  const StepUpFailure();
}
